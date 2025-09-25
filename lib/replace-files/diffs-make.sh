generate_diffs() {
    local src_dir="/etc"
    local -a dot_files=()

    mkdir -p "$DIFFS_DIR"

    # Collect dotfiles into an array (safely)
    mapfile -d '' dot_files < <(find "$ETC_DOTS_DIR" -type f -print0)

    export DIFFS_DIR ETC_DOTS_DIR src_dir

    # Export the function so parallel can use it
    export -f diff_single_file

    parallel --halt now,fail=1 -j 8 diff_single_file ::: "${dot_files[@]}"
}

diff_single_file() {
    local dot_file="$1"
    local rel_path="${dot_file#$ETC_DOTS_DIR/}"
    local src_file="$src_dir/$rel_path"
    local diff_file="$DIFFS_DIR/${rel_path}.diff"

    mkdir -p "$(dirname "$diff_file")"

    # Optional: skip binary/unreadable files
    if ! grep -Iq . "$dot_file"; then
        echo "Skipping binary or unreadable: $dot_file"
        return 0
    fi

    if [[ -f "$dot_file" && ! -f "$src_file" ]]; then
        if diff -u /dev/null "$dot_file" > "$diff_file"; then
            [[ -s "$diff_file" ]] && echo "Diff created (new): $diff_file" || rm -f "$diff_file"
        else
            echo "Failed to diff (new): $dot_file"
        fi
    elif [[ -f "$dot_file" && -f "$src_file" ]]; then
        if diff -u "$src_file" "$dot_file" > "$diff_file"; then
            [[ -s "$diff_file" ]] && echo "Diff created: $diff_file" || rm -f "$diff_file"
        else
            echo "Failed to diff: $rel_path"
        fi
    fi
}
