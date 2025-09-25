generate_diffs() {
    local map_file="etc_list.txt"
    fd -t f -H -L . /etc | sd "^/etc/" "" | sort -u > "$map_file"

    # Get dotfiles (relative paths), diff against real /etc
    fd -t f -H -L . "$ETC_DOTS_DIR" | sd "^$ETC_DOTS_DIR/" "" | sort -u | \
        parallel --halt now,fail=1 -j 8 diff_single_file {}
}

file_in_etc() {
    local rel_path="$1"
    grep -qxF "$rel_path" etc_list.txt
}

diff_single_file() {
    local rel_path="$1"
    local dot_file="$ETC_DOTS_DIR/$rel_path"
    local etc_file="/etc/$rel_path"
    local diff_file="$DIFFS_DIR/${rel_path}.diff"

    mkdir -p "$(dirname "$diff_file")"

    if file_in_etc "$rel_path"; then
        diff -u "$etc_file" "$dot_file" > "$diff_file" 2>/dev/null
    else
        diff -u /dev/null "$dot_file" > "$diff_file" 2>/dev/null
    fi

    if [[ -s "$diff_file" ]]; then
        echo "Diff created: $diff_file"
    else
        rm -f "$diff_file"
    fi
}

generate_patch_map() {
    local map_file="$DIFFS_DIR/map.yml"
    echo "patches:" > "$map_file"

    find "$DIFFS_DIR" -type f -name "*.diff" | sort | while read -r diff_file; do
        local rel_path="${diff_file#$DIFFS_DIR/}"
        local dest_path="/etc/${rel_path%.diff}"
        printf "  - { src: %s, dest: %s }\n" "$diff_file" "$dest_path" >> "$map_file"
    done
}

handle_etc_files() {
    mkdir -p "$DIFFS_DIR"
    generate_diffs
    generate_patch_map
}
