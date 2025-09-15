# Utilities

run_temp_app() {
	local cmd="$1" delay="${2:-5}" pid
	"$cmd" &
	pid=$!
	sleep "$delay"
	kill "$pid" 2>/dev/null
}

app_launch() {
    wl-copy "$RANDOM"
    run_temp_app betterbird 6
    brave &>/dev/null &
    protonmail-bridge &>/dev/null &
    steam-native-runtime &>/dev/null &
    echo "you have 60 seconds before it closes"
    run_temp_app dbeaver 60
}

restore_thunderbird() {
    local profiles_ini="$HOME/.thunderbird/profiles.ini" current_profile dest_dir old_profile
    [[ -f "$profiles_ini" && -r "$profiles_ini" ]]
    current_profile=$(awk -F= '/^\[Install/{f=1} f && /^Default=/{print $2; exit}' "$profiles_ini")
    [[ -n "$current_profile" ]]
    dest_dir="$HOME/.thunderbird/$current_profile"
    [[ -d "$dest_dir" ]]
    old_profile=$(find "$HOME/.thunderbird" -maxdepth 1 -type d -name '*-.default*' ! -name "$current_profile" -printf '%f\n' | head -n1)
    [[ -n "$old_profile" ]]
    cp -r "$HOME/.thunderbird/$old_profile/." "$dest_dir/"
}

main() {
    app_launch
    restore_thunderbird
}
main
