generate_diff() {
    local src_file="$1"
    local dot_file="$2"
    local rel_path="$3"


    # Define the output path for the diff file. The forward slashes in the relative path
    # are replaced with underscores to create a valid filename.
    local output_diff="$DIFFS_DIR/$(echo "$rel_path" | tr '/' '_').diff"
    
    # Case 1: Both files exist.
    if [[ -f "$src_file" && -f "$dot_file" ]]; then
        # 'cmp' compare, '-s' flag suppresses all output.
        # Faster than 'diff' checking if files are identical.
        if ! cmp -s "$src_file" "$dot_file"; then
            echo "Generating diff for modified file: $rel_path"
            diff -u "$src_file" "$dot_file" > "$output_diff"
        fi
    # Case 2: The file exists only in the ETC_DOTS_DIR.
    elif  [[ -f "$dot_file"]]; then
        echo "Generating diff for new file: $rel_path"
        diff -u /dev/null "$dot_file" > "$output_diff"
    fi
}

call_generate_diff() {
    local src_dir="/etc"

    mkdir -p "$DIFFS_DIR" || { echo "Failed to create $DIFFS_DIR"; exit 1; }

    find "$ETC_DOTS_DIR" -type f -print0 | while IFS= read -r -d '' dots_file; do
        rel_path="${dots_file#$ETC_DOTS_DIR/}"
        src_file="$src_dir/$rel_path"

    generate_diff "$src_file" "$dots_file" "$rel_path"
    done
}
