from pathlib import Path


# --- Utility Functions (rest of your original code) ---
def ensure_file_ready(dest_path: Path):
    """Creates the parent directory and ensures the destination file exists."""
    path = Path(dest_path)
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.is_file():
            path.touch()
        return True
    except OSError as e:
        print(f"  [ERROR] Cannot touch file {path}: {e}")
        return False
