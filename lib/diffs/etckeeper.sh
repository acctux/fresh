etckeeper_commit() {
    if [ -z "$1" ]; then
        log INFO "etckeeper_commit usage: $0 <commit_message>"
        exit 1
    fi
    sudo etckeeper commit -m "$1"
}

etckeeper_init() {
        sudo etckeeper init
        etckeeper_commit "/etc with no modifications"
}
