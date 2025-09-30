# ──────────────── USER  Enable──────────────── #
readonly SERV_USER_ENABLE=(
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
    wallpaper.timer
    gcr-ssh-agent.socket
)

# ──────────────── SYSTEM Enable ──────────────── #
readonly SERV_ENABLE=(
    ananicy-cpp.service
    avahi-daemon.service
    bluetooth.service
    chronyd.service
    firewalld.service
    logid.service
    ly.service
    NetworkManager.service
    tuned-ppd.service
    fstrim.timer
    logrotate.timer
    man-db.timer
    paccache.timer
    reflector.timer
)

# ──────────────── SYSTEM Disable ──────────────── #
readonly SERV_DISABLE=(
    systemd-timesyncd.service
)

# ──────────────── SYSTEM Mask ──────────────── #
readonly SERV_MASK=(
    ntpd.service
    ntpdate.service
)
