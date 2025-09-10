#!/usr/bin/env bash

# ──────────────── SERVICES ──────────────── #
SERVENABLE=(
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

SERVDISABLE=(
  systemd-timesyncd.service
)

SERVMASK=(
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