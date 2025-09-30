
create_patch_for_file() {
    local src_file="$1"
    local rel_path="$2"
    local etc_file="/etc/$rel_path"
    local patch_file="$DIFFS_DIR/etc/$rel_path.diff"

    mkdir -p "$(dirname "$patch_file")"

    if [[ -f "$etc_file" ]]; then
        if diff -u "$etc_file" "$src_file" > "$patch_file"; then
            echo "✅ No differences for $rel_path (empty patch)"
            rm -f "$patch_file"
        else
            echo "📦 Patch created: $patch_file"
        fi
    else
        echo "⚠️  Missing in /etc: $etc_file → creating patch from empty file"
        if diff -u /dev/null "$src_file" > "$patch_file"; then
            echo "📄 Created patch for new file: $rel_path"
        fi
    fi
}

create_patches() {
    find "$ETC_DOTS_DIR" -type f | while read -r src_file; do
        rel_path="${src_file#$ETC_DOTS_DIR/}"
        create_patch_for_file "$src_file" "$rel_path"
    done
}
