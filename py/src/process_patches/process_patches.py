from pathlib import Path

from lib.py.src import apply_one_patch
from lib.py.src.ensure_file_ready import ensure_file_ready
from lib.py.src.load_json_list import load_json_list
from lib.py.src.update_patch_state import update_patch_state

PATCH_LIST_JSON = Path("~/fresh/lib/py/patchlist.json").expanduser()
DIFFS_DIR = Path("~/dotcetera").expanduser()


def process_patches():
    """
    Iterates through PATCH_LIST_JSON, checks state, and applies patches.
    """
    print("[INFO] Starting Patch Application...")
    patch_list: list[dict[str, str]] = []
    patch_list = load_json_list(PATCH_LIST_JSON)

    if not patch_list:
        print("[WARNING] Patch list is empty or could not be loaded. Aborting.")
        return

    total_patches = len(patch_list)

    # Correctly iterate through the loaded list
    for i, item in enumerate(patch_list):
        # Ensure required keys exist in the dictionary
        if "src" not in item or "dest" not in item:
            print(
                f"[{i + 1}/{total_patches}] [CRITICAL] Skipping malformed patch entry: {item}"
            )
            continue

        src_diff = (
            DIFFS_DIR / item["src"]
        )  # Renamed from src_path to src_diff for clarity
        dest_path = Path(item["dest"])
        dest_file_str = item["dest"]  # Used for tracking applied state

        print(f"\n[{i + 1}/{total_patches}] Processing {dest_path}...")

        # 1. Check if the patch file (source diff) exists
        if not src_diff.exists():
            print(f"  [SKIPPED] Patch file not found: {src_diff}")
            continue

        # 3. Ensure the destination file is ready (exists, permissions, etc.)
        if ensure_file_ready(dest_path):
            # 4. Apply the patch
            if apply_one_patch:
                # 5. Record successful application
                _ = update_patch_state(dest_file_str)
            else:
                print(f"  [CRITICAL] Failed to apply patch to {dest_path}.")
        else:
            # The original code had a misplaced print inside an else block
            print("  [CRITICAL] Skipping diff due to destination file issue.")

    print("\n--- Patch Application Complete ---")
