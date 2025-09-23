# ──────────────── PACMAN ──────────────── #
BASE_PAC=(
    base-devel
    keychain
    networkmanager          # Network manager daemon
    openssh
    reflector
    rsync
    wireless-regdb
)

# ──────────────── PACMAN ──────────────── #
PACMAN=(
    # ------- System Core / Kernel / Boot / Firmware --------
    acpi                    # Power & thermal info
    amd-ucode               # CPU microcode updates for AMD CPUs
    dosfstools
    exfatprogs              # exFAT filesystem tools
    fwupd                   # Firmware updater
    mesa
    mesa-utils
    sof-firmware            # Sound Open Firmware
    smartmontools           # SMART disk monitoring tools
    udisks2-btrfs           # Btrfs support for UDisks2
    vulkan-icd-loader       # Vulkan loader
    vulkan-radeon           # Vulkan driver for AMD

    # ------- NVIDIA --------
    dkms                    # Kernel module manager
    lib32-nvidia-utils      # 32-bit NVIDIA driver support
    libva-nvidia-driver     # Nvidia VA-API driver
    linux-headers           # Kernel headers (needed for DKMS)
    libxnvctrl              # Nvidia X control library
    ntfs-3g                 # NTFS filesystem support
    nvidia-dkms             # Nvidia kernel modules
    nvidia-prime            # Nvidia PRIME support

    # ------ System Utilities / Admin Tools ------
    btop                    # Resource monitor
    firejail                # Sandboxing
    keyd                    # Keyboard remapping daemon
    logrotate               # Rotates system logs
    man-db                  # Manual page database
    man-pages               # POSIX and GNU man pages
    tealdeer                # Fast tldr client
    tuned-ppd               # Power management tool
    protonmail-bridge       # ProtonMail IMAP bridge
    powertop                # Power consumption monitor
    solaar                  # Logitech device manager

    # ------ Networking / Internet / DNS ------
    blueman                 # Bluetooth manager
    bluez-tools
    chrony                  # Time sync service (NTP)
    dnsmasq                 # Lightweight DNS/DHCP server
    ldns                    # DNS tools
    network-manager-applet
    nss-mdns                # Multicast DNS support
    openresolv              # DNS resolver config support
    sshfs                   # Filesystem over SSH
    iwd                     # Wireless daemon
    firewalld               # Firewall management

    # ---------- Security / Secrets ----------
    gnome-keyring           # Keyring daemon
    keepassxc               # Password manager (Qt)
    libgnome-keyring        # Library for GNOME keyring
    libsecret               # Secret storage API
    pinentry                # GPG password prompt
    seahorse                # GNOME key manager

    # -------------- Audio / Sound -------------
    alsa-firmware
    alsa-utils
    gst-plugin-pipewire     # PipeWire GStreamer plugin
    pipewire-alsa           # ALSA compatibility for PipeWire
    pipewire-pulse          # PulseAudio compatibility for PipeWire

    # ---------- Hyprland / Desktop Components -----------
    archlinux-xdg-menu
    brightnessctl           # Backlight controller
    bc                      # for cpu/memory modules
    hyprland                # Wayland compositor
    hypridle                # Idle manager for Hyprland
    hyprlock                # Lock screen
    hyprpicker              # Color picker
    hyprshot                # Screenshot tool
    ly                      # TUI display manager
    mako                    # Wayland notification daemon
    nwg-clipman             # Clipboard manager for Wayland
    nwg-look                # GTK theme preview & changer
    polkit-gnome
    satty
    swww
    uwsm                    # Window/session manager
    waybar                  # Status bar for Wayland compositors
    wofi
    wl-clipboard            # Clipboard utilities for Wayland
    wlogout
    xdg-desktop-portal-gtk  # XDG portal for GTK apps
    xdg-desktop-portal-hyprland # XDG portal for Hyprland
    xdg-user-dirs           # User directories management
    # waybar
    gobject-introspection
    libappindicator-gtk3
    chrono-date-3.0.4-1
    scdoc-1.11.3-1

    # ---------- Appearance -----------
    capitaine-cursors       # Cursor theme
    dconf-editor
    kvantum
    noto-fonts              # Noto font family
    otf-font-awesome        # Font Awesome icons
    ttf-caladea             # Caladea font
    ttf-cascadia-mono-nerd  # Cascadia Mono Nerd Font
    ttf-dejavu              # DejaVu fonts
    ttf-roboto-mono-nerd    # Roboto Mono Nerd Font

    # ----------- Gtk Applications --------------
    nemo-fileroller
    nemo-image-converter
    nemo-seahorse
    nemo-image-converter
    nemo-emblems
    nemo-audio-tab
    nemo-preview
    gvfs-mtp
    gvfs-gphoto2
    cheese
    gthumb
    baobab
    gnome-logs
    kdeconnect              # Device integration

    # --------- Databases / SQL / Data Tools ----------
    dbeaver                 # SQL GUI client
    csvkit                  # CSV tools
    miller                  # CSV processor
    mariadb-libs            # MariaDB client libraries
    mariadb                 # MariaDB server

    # ------------ Multimedia --------------
    gimp                    # Image editor
    graphicsmagick          # Image processing tools
    gst-libav               # GStreamer plugin for libav
    gst-plugin-mp4          # GStreamer MP4 plugin
    handbrake               # Video transcoder
    inkscape                # Vector graphics editor
    playerctl               # Control media players from CLI
    haruna                  # Music player, KDE but didn't like celluloid

    # ----------- CLI environment -------------
    alacritty               # GPU-accelerated terminal
    bash-completion
    bat-extras              # Extra tools for bat (cat clone)
    fzf                     # Fuzzy finder
    eza
    less                    # File pager
    navi                    # Interactive cheatsheets
    skim                    # Fuzzy finder (alternative to fzf)
    starship                # Shell prompt
    zsh-autocomplete        # Zsh autocomplete plugin
    zsh-completions         # Zsh completions
    zsh-syntax-highlighting # Zsh syntax highlighting

    # ------------ CLI Script tools ------------
    aria2                   # Download utility
    choose                  # CLI selector
    dasel                   # YAML/JSON/TOML query/update tool
    fd                      # Fast file search
    grex                    # Regex generator
    parallel                # Parallel command runner
    pv                      # Pipe viewer
    sd                      # Sed alternative
    trash-cli               # Trash management CLI
    wget                    # Network downloader
    xmlstarlet              # Manipulating XML files.
    yq                      # YAML processor

    # ------------ GUI Non-KDE ----------------
    gnucash                 # Personal finance manager
    gnumeric                # Spreadsheet app
    hledger                 # Accounting tool
    qbittorrent             # Qt BitTorrent client
    qalculate-qt            # Calculator app (Qt)

    # ---------- Console Applications ---------------
    fdupes                  # Find duplicate files
    git-delta               # Git diff viewer
    github-cli              # GitHub CLI tool
    lazygit                 # Git TUI client
    remind                  # Reminder and calendar program.
    stow                    # Symlink farm manager
    zoxide                  # Smarter cd alternative
    watchexec
    visidata                # Interactive data exploration

    # ---------- Shell / Scripting Enhancements -----------
    expac                   # Query pacman database
    pacutils                # Pacman helper tools
    pacman-contrib          # Pacman extras (paccache, checkupdates)
    rebuild-detector        # Detect package rebuilds

    # --------- Programming / Dev Tools -------------
    ccache                  # Compiler caching
    clang                   # C/C++ compiler
    eslint                  # JavaScript linter
    ipython
    lua-sec                 # SSL support for Lua
    luarocks                # Lua package manager
    mise                    # Version/environment manager
    neovim-lspconfig        # LSP config for Neovim
    python-mysqlclient      # MySQL client for Python
    python-polars           # Dataframe library
    python-pandas           # Data analysis library
    python-plotly           # Interactive visualization library
    python-statsmodels
    python-xlsxwriter       # Excel writing library
    shfmt                   # Shell script formatter
    rust-analyzer           # Rust language server
    tree-sitter-bash        # Bash grammar for tree-sitter
    tree-sitter-python      # Python grammar for tree-sitter
    uv
    zed                     # A high-performance, collaborative code editor.

    # ----------- Spell Checking / Hyphenation --------------
    hunspell-en_us          # English spell checker
    hyphen-en               # English hyphenation patterns

    # ---------------- Games ----------------
    gamemode                # Gaming performance tool
    gnuchess                # Chess engine
    lib32-gamemode          # 32-bit GameMode support
    lib32-mangohud          # 32-bit performance overlay
    lutris                  # Game manager
    mangohud                # Performance overlay
    mgba-qt                 # Game Boy Advance emulator (Qt frontend)
    pychess
    steam-native-runtime    # Steam runtime for native games
    umu-launcher            # A lightweight and simple application launcher.
    vkd3d                   # Vulkan-based Direct3D 12 translation layer
    wine-staging            # Wine with staging patches
    wine-mono               # Mono runtime for Wine
    winetricks              # Wine helper scripts

    # ------------ Miscellaneous / Other Tools --------------
    tesseract-data-eng      # OCR data
    webkit2gtk
    unarchiver              # Archive extraction tool
    yt-dlp                  # Youtube downloader

    # ------------ Chaotic-Aur --------------
    anki
    ayugram-desktop-git
    betterbird-bin
    dxvk-mingw-git
    brave-bin
    localsend
    logiops
    ocrmypdf
    octopi
    onlyoffice-bin
    paru
    proton-ge-custom-bin
    qt6ct-kde
    rpcs3-git
    zapzap
    zsh-vi-mode
)

# ──────────────── AUR ──────────────── #
AUR=(
    mycli
    python-gs-quant
    python-yfinance
    python-quantlib
    quantlib
    surfshark-client
)

    # ----------- KDE Applications --------------
    # ark                     # Archive manager
    # dolphin                 # KDE file manager
    # filelight               # Disk usage viewer
    # gwenview                # KDE image viewer
    # haruna                  # Music player
    # kamoso                  # Webcam app
    # ksystemlog              # KDE log viewer
    # kio-admin               # KDE admin tools helper
    # kdeconnect              # Device integration
