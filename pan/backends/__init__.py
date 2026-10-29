from pan.backends.base import Backend

__all__ = ["Backend", "get_backend"]


def get_backend(name: str, **kwargs) -> Backend:
    if name == "jev":
        from pan.backends.jev import JevBackend

        return JevBackend(**kwargs)
    raise ValueError(f"unknown backend: {name}")
