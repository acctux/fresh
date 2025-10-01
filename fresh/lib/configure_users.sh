configure_users() {
    root_password=$(get_password "Enter password")
    info "Configuring users"
    echo "root:$root_password" | arch-chroot "$MOUNT_POINT" chpasswd

    arch-chroot "$MOUNT_POINT" useradd -m -s "/bin/zsh" "$USERNAME"
    echo "$USERNAME:$root_password" | arch-chroot "$MOUNT_POINT" chpasswd

    cat > "$MOUNT_POINT/etc/sudoers.d/$USERNAME" <<EOF
$USERNAME ALL=(ALL:ALL) ALL
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/udisksctl
Defaults:$USERNAME timestamp_timeout=-1
Defaults passwd_tries=10
EOF
    chmod 440 "$MOUNT_POINT/etc/sudoers.d/$USERNAME"
    success "Users configured successfully"
}

ansible_etc_playbook() {
    info "Running ansible playbook on etc files"
    ansible-galaxy collection install community.general
    ansible-playbook -i ~/fresh/fresh_ans_inv.yml ~/fresh/fresh_ans_play.yml
}
