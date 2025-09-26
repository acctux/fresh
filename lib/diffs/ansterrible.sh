ansible_plugins() {
    ansible-galaxy collection install ansible.posix
}
apply_ansible() {
#    cp "$HOME/fresh/lib/diffs/patch.yml" "$DIFFS_DIR"
    cd "$DIFFS_DIR"
    ansible-playbook patch.yml --ask-become-pass
}
