-- Per-case signal profile for RCAEval RE2/RE3. Uses labels; never shown to the agent.
-- Run from the repo root:  duckdb -no-agent < bench/datasets/profile.sql
-- Output: results/profile/cases.parquet, one row per case.
-- "before" and "after" are the 5 minutes on each side of the injection time.
-- Covers logs, traces, and metrics.

CREATE MACRO case_of(f) AS split_part(f, '/', 3);

CREATE TABLE cases AS
SELECT
    case_of(filename) AS case_id,
    left(case_of(filename), 5) AS suite,
    split_part(case_of(filename), '_', 2) AS rc_service,
    split_part(case_of(filename), '_', 3) AS fault,
    column0::BIGINT AS inject_t
FROM read_csv('data/rcaeval/re*/inject_time.txt', header = false, filename = true,
              columns = {'column0': 'VARCHAR'});

CREATE TABLE logs AS
SELECT
    case_of(filename) AS case_id,
    timestamp AS t,
    container_name AS service,
    regexp_matches(message, '(?i)error|exception|fail|timeout') AS is_err
FROM read_parquet('data/rcaeval/re*/logs.parquet', filename = true);

CREATE TABLE spans AS
SELECT
    case_of(filename) AS case_id,
    startTime // 1000000 AS t,
    serviceName AS service,
    duration,
    coalesce(statusCode NOT IN (0, 200), false) AS is_err
FROM read_parquet('data/rcaeval/re*/traces.parquet', filename = true, union_by_name = true);

-- Metrics are wide (one column per <service>_<metric>, varying by case); unpivot to long.
-- Service names use '-', never '_', so the last '_' splits service from metric.
CREATE TABLE metrics AS
WITH w AS (
    SELECT case_of(m.filename) AS case_id, m.* EXCLUDE (filename),
           CASE WHEN m.time < c.inject_t THEN 'before' ELSE 'after' END AS side
    FROM read_parquet('data/rcaeval/re*/metrics.parquet', filename = true, union_by_name = true) m
    JOIN cases c ON c.case_id = case_of(m.filename)
    WHERE m.time >= c.inject_t - 300 AND m.time < c.inject_t + 300
)
SELECT case_id, side,
       regexp_extract(series, '^(.*)_[^_]+$', 1) AS service,
       regexp_extract(series, '_([^_]+)$', 1) AS metric,
       v
FROM (UNPIVOT w ON COLUMNS(* EXCLUDE (case_id, time, side)) INTO NAME series VALUE v);

-- Shift in mean, in units of the "before" spread. The spread is floored at 10% of the
-- "before" mean so near-constant series don't produce unbounded scores.
CREATE TABLE metric_z AS
SELECT case_id, service, metric,
       (avg(v) FILTER (WHERE side = 'after') - avg(v) FILTER (WHERE side = 'before'))
       / nullif(greatest(stddev_samp(v) FILTER (WHERE side = 'before'),
                         0.1 * abs(avg(v) FILTER (WHERE side = 'before'))), 0) AS z
FROM metrics
GROUP BY ALL;

-- Rank of the root-cause service among all services by its largest |z|.
-- Ties count against the root cause (rank = services scoring >= it), so rank 1 means
-- one aggregate query over metrics points at the answer and nothing else.
CREATE TABLE metric_profile AS
WITH s AS (
    SELECT case_id, service, max(abs(z)) AS max_z, arg_max(metric, abs(z)) AS top_metric
    FROM metric_z
    WHERE z IS NOT NULL
    GROUP BY ALL
),
r AS (
    SELECT *, count(*) OVER (PARTITION BY case_id ORDER BY max_z DESC) AS rk,
           count(*) OVER (PARTITION BY case_id) AS n
    FROM s
)
SELECT r.case_id,
       top_metric AS rc_metric_top,
       max_z AS rc_metric_max_z,
       rk AS rc_metric_rank,
       n AS metric_services
FROM r JOIN cases c ON c.case_id = r.case_id AND c.rc_service = r.service;

-- Same idea for logs: rank services by growth in error-line count (+1 smoothed).
CREATE TABLE log_rank AS
WITH s AS (
    SELECT l.case_id, l.service, c.rc_service,
           (count(*) FILTER (WHERE l.t >= c.inject_t AND l.t < c.inject_t + 300 AND is_err) + 1)
           / (count(*) FILTER (WHERE l.t >= c.inject_t - 300 AND l.t < c.inject_t AND is_err) + 1) AS err_growth
    FROM logs l JOIN cases c USING (case_id)
    GROUP BY ALL
),
r AS (
    SELECT *, count(*) OVER (PARTITION BY case_id ORDER BY err_growth DESC) AS rk,
           count(*) OVER (PARTITION BY case_id) AS n
    FROM s
)
SELECT case_id, rk AS rc_log_rank, n AS log_services
FROM r
WHERE service = rc_service;

CREATE TABLE log_profile AS
WITH w AS (
    SELECT l.*, c.rc_service, c.inject_t,
           CASE WHEN l.t >= c.inject_t - 300 AND l.t < c.inject_t THEN 'before'
                WHEN l.t >= c.inject_t AND l.t < c.inject_t + 300 THEN 'after' END AS side
    FROM logs l JOIN cases c USING (case_id)
)
SELECT
    case_id,
    count(*) AS log_lines,
    count(*) FILTER (WHERE service = rc_service AND side = 'before') AS rc_lines_before,
    count(*) FILTER (WHERE service = rc_service AND side = 'after') AS rc_lines_after,
    count(*) FILTER (WHERE service = rc_service AND side = 'before' AND is_err) AS rc_err_before,
    count(*) FILTER (WHERE service = rc_service AND side = 'after' AND is_err) AS rc_err_after,
    count(*) FILTER (WHERE side = 'before' AND is_err) AS all_err_before,
    count(*) FILTER (WHERE side = 'after' AND is_err) AS all_err_after
FROM w
GROUP BY case_id;

CREATE TABLE trace_profile AS
WITH w AS (
    SELECT s.*, c.rc_service,
           CASE WHEN s.t >= c.inject_t - 300 AND s.t < c.inject_t THEN 'before'
                WHEN s.t >= c.inject_t AND s.t < c.inject_t + 300 THEN 'after' END AS side
    FROM spans s JOIN cases c USING (case_id)
)
SELECT
    case_id,
    count(*) AS spans,
    count(*) FILTER (WHERE service = rc_service AND side = 'before' AND is_err) AS rc_span_err_before,
    count(*) FILTER (WHERE service = rc_service AND side = 'after' AND is_err) AS rc_span_err_after,
    median(duration) FILTER (WHERE service = rc_service AND side = 'before') AS rc_p50_dur_before,
    median(duration) FILTER (WHERE service = rc_service AND side = 'after') AS rc_p50_dur_after
FROM w
GROUP BY case_id;

COPY (
    SELECT * FROM cases
    LEFT JOIN log_profile USING (case_id)
    LEFT JOIN trace_profile USING (case_id)
    LEFT JOIN metric_profile USING (case_id)
    LEFT JOIN log_rank USING (case_id)
    ORDER BY case_id
) TO 'results/profile/cases.parquet' (FORMAT parquet);
