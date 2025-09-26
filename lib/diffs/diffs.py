import os
import subprocess
from pathlib import Path
from patches import PATCH_LIST


def ensure_file_ready(dest_path):
    """Creates the parent directory and ensures the destination file exists."""
    path = Path(dest_path)
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.touch(exist_ok=True)
        return True
    except OSError as e:
        print(f"  [ERROR] Cannot touch file {path}: {e}")
        return False


def apply_patch(src_diff, dest_file):
    """Applies the diff file to the destination file using the 'patch' command."""
    src_path = Path(src_diff)
    if not src_path.is_file():
        print(f"  [SKIPPED] Patch source file not found: {src_diff}")
        return

    cmd = [
        "sudo",
        "patch",
        "-p0",  # Strip level 0
        "-N",  # Ignore if already applied
        "-i",
        str(src_path),
        dest_file,
    ]

    try:
        result = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print(f"  [SUCCESS] Patched: {dest_file}")
        elif (
            "already applied" in result.stderr
            or "Skipping patch" in result.stderr
            or result.returncode == 1
        ):
            print(f"  [INFO] Patch already applied or skipped: {dest_file}")
            # Removes rejection files
            rejected_file = Path(f"{dest_file}.rej")
            if rejected_file.exists():
                rejected_file.unlink()
        else:
            print(
                f"  [FAILED] Patching {dest_file} failed with code {result.returncode}."
            )
            print(result.stderr)
            print(result.stdout)

    except Exception as e:
        print(f"  [FATAL] Unexpected error: {e}")


def main():
    """Main execution function."""
    print("--- Starting Patch Application ---")

    for i, item in enumerate(PATCH_LIST):
        src = item["src"]
        dest = item["dest"]
        print(f"\n[{i + 1}/{len(PATCH_LIST)}] Processing {dest}...")

        if ensure_file_ready(dest):
            apply_patch(src, dest)
        else:
            print(f"  [CRITICAL] Skipping diff due to destination file issue.")

    print("\n--- Patch Application Complete ---")


if __name__ == "__main__":
    # Check for root privileges since operations often target /etc.
    if os.geteuid() != 0:
        print("\n[ERROR] This script must be run with root privileges (sudo).\n")
        exit(1)

    main()
