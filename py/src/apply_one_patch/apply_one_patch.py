import subprocess
from pathlib import Path


def apply_patch(src_diff: Path, dest_file: Path):
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
