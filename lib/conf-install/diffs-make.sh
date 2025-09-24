#!/bin/bash

# Define directories
SRC_DIR="/etc"                          # Source directory for original files
DOTS_DIR="/home/nick/Lit/dotfiles/etc"     # Directory with reference files
DIFFS_DIR="$HOME/dotcetera"            # Directory to store diff files

# Exit on any error
set -e

# Create the diffs directory if it doesn't exist
mkdir -p "$DIFFS_DIR" || { echo "Failed to create $DIFFS_DIR"; exit 1; }

# Function to generate diff for a file
generate_diff() {
    local src_file="$1"   # File in SRC_DIR
    local dot_file="$2"  # File in DOTS_DIR
    local rel_path="$3"   # Relative path of the file
    local output_diff="$DIFFS_DIR/$(echo "$rel_path" | tr '/' '_').diff"

    # Case 1: Both files exist, check if they differ
    if [[ -f "$src_file" && -f "$dot_file" ]]; then
        if ! cmp -s "$src_file" "$dot_file"; then
            echo "Generating diff for modified file: $rel_path"
            diff -u "$src_file" "$dot_file" > "$output_diff" || {
                echo "Failed to generate diff for $rel_path"
                return 1
            }
        else
            echo "No differences for: $rel_path"
        fi
    # Case 2: File exists only in DOTS_DIR (new file)
    elif [[ -f "$dot_file" ]]; then
        echo "Generating diff for new file: $rel_path"
        diff -u /dev/null "$dot_file" > "$output_diff" || {
            echo "Failed to generate diff for $rel_path"
            return 1
        }
    else
        echo "Warning: $rel_path not found in either directory"
        return 0
    fi
}

# Find all files in DOTS_DIR and process them
find "$DOTS_DIR" -type f -print0 | while IFS= read -r -d '' dots_file; do
    # Get the relative path from DOTS_DIR
    rel_path="${dots_file#$DOTS_DIR/}"
    src_file="$SRC_DIR/$rel_path"

    # Generate diff for this file
    generate_diff "$src_file" "$dots_file" "$rel_path"
done

echo "Diffs created in $DIFFS_DIR/"
