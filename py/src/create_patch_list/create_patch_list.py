from pathlib import Path

PATCH_LIST_JSON = Path("~/fresh/lib/py/patchlist.json").expanduser()


def create_patch_list(dots_dir: Path) -> list[dict[str, str]]:
    """
    :return: A list of {"src": "...", "dest": "..."} dictionaries.
    """
    patch_list: list[dict[str, str]] = []

    if not dots_dir.is_dir():
        print(f"❌ Error: Source directory not found at {dots_dir.resolve()}")
        return patch_list

    print(f"--- Scanning {dots_dir.name} for files... ---")

    # Iterate recursively through all files in the dots directory
    for src_file in dots_dir.rglob("*"):
        if src_file.is_file():
            # Get the path relative to the source root (ETC_DOTS_DIR)
            rel_path = src_file.relative_to(dots_dir)

            # 1. Calculate the 'src' path: Assumed to be relative to the directory
            # that contains $HOME/dotcetera, typically the project root.
            # Example: etc/some/file.diff
            src_relative = Path("etc") / f"{rel_path}.diff"
            # Use .as_posix() for consistent forward slashes in JSON
            src_path = str(src_relative.as_posix())

            # 2. Calculate the 'dest' path (absolute path in /etc)
            # Example: /etc/some/file
            dest_path = str(Path("/etc") / rel_path)

            patch_list.append({"src": src_path, "dest": dest_path})

    return patch_list
