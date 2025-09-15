# ──────────────── SERVICES ──────────────── #
SERV_ENABLE=(
  avahi-daemon.service
  bluetooth.service
  chronyd.service
  dnsmasq.service
  firewalld.service
  ly.service
  NetworkManager.service
  tlp.service
  fstrim.timer
  logrotate.timer
  man-db.timer
  paccache.timer
  reflector.timer
)

SERV_USER_ENABLE=(
    pipewire.service
    pipewire-pulse.service
    wireplumber.service
    gcr-ssh-agent.socket
)

SERV_DISABLE=(
  systemd-timesyncd.service
)

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
