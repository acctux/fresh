import json
from pathlib import Path


# Assuming the list contains dictionaries for patches, we use List[Dict[str, str]].
# If the content is uncertain, List[Any] or just List can be used.
def load_json_list(file_path: Path) -> list[dict[str, str]]:
    """
    Loads a JSON file expected to contain a list of dictionaries.
    Returns the list on success, or an empty list on failure.
    """
    if not file_path.exists():
        print(f"[FATAL] Config not found: {file_path.resolve()}")
        return []

    try:
        with open(file_path, "r") as f:
            # Load the data directly into a local variable
            data = json.load(f)

            if isinstance(data, list):
                # Now that the input 'data' argument is removed, this logic is clean
                return data
            else:
                print(
                    f"[ERROR] Expected a list in {file_path.resolve()}, got {type(data).__name__}."
                )
                return []

    except (FileNotFoundError, json.JSONDecodeError, OSError) as e:
        # Added OSError for robustness (e.g., permissions issues)
        print(f"[FATAL] Error loading {file_path.resolve()}: {e}")
        return []
