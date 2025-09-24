# ──────────────── USER  ──────────────── #
readonly USER_GROUPS=(
    input
    audio
    video
    network
    storage
    rfkill
#    kvm
    docker
    games
    gamemode
    log
)

# User services
SERV_USER_ENABLE=(
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
    wallpaper.timer
    gcr-ssh-agent.socket
)

# ──────────────── SYSTEM ──────────────── #
# Enable
SERV_ENABLE=(
    avahi-daemon.service
    bluetooth.service
    chronyd.service
    dnsmasq.service
    firewalld.service
    logid.service
    logid-check.service
    ly.service
    NetworkManager.service
    tuned-ppd.service
    fstrim.timer
    logrotate.timer
    man-db.timer
    paccache.timer
    reflector.timer
)
# Disable
SERV_DISABLE=(
    systemd-timesyncd.service
)
# Mask
SERV_MASK=(
    auditd.service
    audit-rules.service
    ebtables.service
    ipset.service
    ntpd.service
    ntpdate.service
    plymouth-quit-wait.service
    plymouth-start.service
    sntp.service
    syslog.service
    systemd-timesyncd.service
)
