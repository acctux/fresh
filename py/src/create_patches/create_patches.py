import subprocess
from pathlib import Path

DIFFS_DIR = Path("~/dotcetera").expanduser()
ETC_DOTS_DIR = Path("~/Lit/dotfiles/etc")


def create_patch_for_file(src_file: Path, rel_path: str):
    """Creates a unified diff (patch) for a file."""
    etc_file = Path("/etc") / rel_path
    patch_file = DIFFS_DIR / "etc" / f"{rel_path}.diff"
    patch_file.parent.mkdir(parents=True, exist_ok=True)

    old_file = str(etc_file) if etc_file.is_file() else "/dev/null"

    try:
        # Run diff -u (return code 1 is differences, 0 is identical)
        result = subprocess.run(
            ["diff", "-u", old_file, str(src_file)],
            capture_output=True,
            text=True,
            check=False,
        )

        if result.returncode == 0:
            print(f"✅ No changes for {rel_path}")
            patch_file.unlink(missing_ok=True)
        elif result.returncode == 1:
            _ = subprocess.run(
                ["diff", "-u", "/dev/null", str(src_file)],
                stdout=open(patch_file, "w"),
                check=True,
            )
        else:
            print(f"❌ Error during diff for {rel_path} (Code {result.returncode})")

    except Exception as e:
        print(f"❌ Fatal error for {rel_path}: {e}")


def create_patches():
    """Loops through all files and creates patches."""
    if not ETC_DOTS_DIR.is_dir():
        print(f"Error: Source not found at {ETC_DOTS_DIR.resolve()}")
        return

    DIFFS_DIR.mkdir(exist_ok=True)
    print(f"--- Scanning {ETC_DOTS_DIR} ---")

    for src_file in ETC_DOTS_DIR.rglob("*"):
        if src_file.is_file():
            rel_path = str(src_file.relative_to(ETC_DOTS_DIR))
            create_patch_for_file(src_file, rel_path)

    print("--- Complete ---")
