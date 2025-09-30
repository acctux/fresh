[Unit]
Description=Run script before desktop environment
Before=graphical.target
DefaultDependencies=no
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/path/to/script.sh
ExecStartPost=/bin/systemctl disable runearly.service && rm /path/to/script

[Install]
WantedBy=graphical.target
