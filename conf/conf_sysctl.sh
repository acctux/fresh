# ──────────────── USER  Enable──────────────── #
readonly SERV_USER_ENABLE=(
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
    wallpaper.timer
    gcr-ssh-agent.socket
)

# ──────────────── SYSTEM Enable ──────────────── #
function serv_enable {
    systemctl enable \
        acpid.service \
        ananicy-cpp.service \
        avahi-daemon.service \
        bluetooth.service \
        firewalld.service \
        iwd.service \
        logid.service \
        ly.service \
        ntpd.service \
        tlp.service \
        fstrim.timer \
        logrotate.timer \
        man-db.timer \
        paccache.timer \
        reflector.timer
}
export -f serv_enable
