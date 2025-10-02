

configure_users() {
    if [ $(whoami) = "root"  ]; then
        PASSWORD=$(get_password "Enter password")
        info "Configuring users"
        echo "root:$root_password" | arch-chroot "$MOUNT_POINT" chpasswd
        groupadd games gamemode
        useradd -m -G wheel power input audio video network storage rfkill log games gamemode -s /bin/zsh $USERNAME
        echo "$USERNAME created, home directory created."

    # use chpasswd to enter $USERNAME:$password
        echo "$USERNAME:$PASSWORD" | chpasswd
        echo "$USERNAME password set"

	    cp -R $HOME/fresh "$HOME_MNT"/
        chown -R $USERNAME: "$HOME_MNT"/ArchTitus
        echo "ArchTitus copied to home directory"

	    echo $HOSTNAME > /etc/hostname
    else
        echo "You are already a user proceed with aur installs"
    fi
}

sudoers_permissions() {
    cat > "$MOUNT_POINT/etc/sudoers.d/$USERNAME" <<EOF
$USERNAME ALL=(ALL:ALL) ALL
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/udisksctl
Defaults:$USERNAME timestamp_timeout=-1
Defaults passwd_tries=10
EOF
    chmod 440 "$MOUNT_POINT/etc/sudoers.d/$USERNAME"
    success "Users configured successfully"
}


# Export system units array (run once at script startup)
system_units_array() {
  mapfile -t SYSTEM_UNITS < <(systemctl list-unit-files --type=service,timer,socket --no-legend | awk '{print $1}')
  export SYSTEM_UNITS
}

enable_user_services() {
  log INFO "Enabling system units..."
  for unit in "${SERV_ENABLE[@]}"; do
    if [[ " ${SYSTEM_UNITS[*]} " =~ " ${unit} " ]]; then
      systemctl --user enable "$unit"
    else
      log WARNING "Unit $unit not found"
    fi
  done
}

# .ssh/config
Host *
    # Use GNOME Keyring's SSH agent for key management
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519

    # Multiplexing setup for efficient connections
    ControlPath ~/.ssh/cm-%r@%h:%p.sock
    ControlMaster auto
    ControlPersist 30m

    # Additional settings for reliability
    ServerAliveInterval 120
    ServerAliveCountMax 3
dingo() {
    configure_users
    sudoers_permissions
}
