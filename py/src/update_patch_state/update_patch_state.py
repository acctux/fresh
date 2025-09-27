import os
import json
from pathlib import Path

ETC_FLAG_JSON = Path("~/fresh/lib/py/applied_patches.json").expanduser()


# FIX: Initialize applied_list to an empty list, as it's the safe starting point
def update_patch_state(file_path: str | None = None) -> list[str]:
    # FIX APPLIED HERE:
    applied_list: list[str] = []  # safe_load_json_list was undefined

    # 1. Load the existing state
    if os.path.exists(ETC_FLAG_JSON):
        try:
            with open(ETC_FLAG_JSON, "r") as f:
                loaded_data = json.load(f)
                if isinstance(loaded_data, list):
                    # Ensure the loaded list only contains strings
                    applied_list = [
                        str(item) for item in loaded_data if isinstance(item, str)
                    ]

        except (json.JSONDecodeError, IOError):
            print(
                f"[ERROR] Could not load {ETC_FLAG_JSON}. Starting with an empty list."
            )

    # 2. Add the new file path and save if provided
    if file_path:
        if file_path not in applied_list:
            applied_list.append(file_path)
            # Save the updated state
            try:
                with open(ETC_FLAG_JSON, "w") as f:
                    json.dump(applied_list, f, indent=2)
            except IOError as e:
                print(f"[ERROR] Could not save state file {ETC_FLAG_JSON}: {e}")

    return applied_list
