# ──────────────── PACMAN ──────────────── #
BASE_PAC=(
    openssh
    keychain
    reflector
    rsync
    base-devel
    wireless-regdb
)

# ──────────────── PACMAN ──────────────── #
PACMAN=(
    # ------- System Core / Kernel / Boot / Firmware --------
    acpi                    # Power & thermal info
    amd-ucode               # CPU microcode updates for AMD CPUs
    dkms                    # Kernel module manager
    exfatprogs              # exFAT filesystem tools
    fwupd                   # Firmware updater
#    lib32-nvidia-utils      # 32-bit NVIDIA driver support
#    libva-nvidia-driver     # Nvidia VA-API driver
#    linux-headers           # Kernel headers (needed for DKMS)
#    libxnvctrl              # Nvidia X control library
    mesa
    mesa-utils
    ntfs-3g                 # NTFS filesystem support
#    nvidia-dkms             # Nvidia kernel modules
#    nvidia-prime            # Nvidia PRIME support
    sof-firmware            # Sound Open Firmware
    smartmontools           # SMART disk monitoring tools
    udisks2-btrfs           # Btrfs support for UDisks2
    vulkan-icd-loader       # Vulkan loader
#    vulkan-radeon           # Vulkan driver for AMD

    # ------ System Utilities / Admin Tools ------
    btop                    # Resource monitor
#    firejail                # Sandboxing
#    keyd                    # Keyboard remapping daemon
#    logrotate               # Rotates system logs
#    man-db                  # Manual page database
#    man-pages               # POSIX and GNU man pages
#    tealdeer                # Fast tldr client
#    tlp                     # Power management tool
#    procs                   # Process viewer
#    protonmail-bridge       # ProtonMail IMAP bridge
#    powertop                # Power consumption monitor
#    solaar                  # Logitech device manager

    # ------ Networking / Internet / DNS ------
#    bind                    # DNS server tools
#    blueman                 # Bluetooth manager
#    bluez-tools
    chrony                  # Time sync service (NTP)
    dnsmasq                 # Lightweight DNS/DHCP server
#    ethtool                 # Ethernet tool
    networkmanager          # Network manager daemon
#    nss-mdns                # Multicast DNS support
#    openresolv              # DNS resolver config support
#    sshfs                   # Filesystem over SSH
    wireless-regdb          # Wireless regulatory database
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
#    alsa-firmware
#    alsa-utils
#    gst-plugin-pipewire     # PipeWire GStreamer plugin
    pamixer                 # CLI audio control
    pavucontrol             # PulseAudio volume control
    pipewire-alsa           # ALSA compatibility for PipeWire
    pipewire-pulse          # PulseAudio compatibility for PipeWire

    # ---------- Hyprland / Desktop Components -----------
    archlinux-xdg-menu
    brightnessctl           # Backlight controller
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
    snixembed               # Notification daemon for Sway/Wayland
    swaybg                  # Background setter for Sway
    swayosd                 # On-screen display for Sway
    uwsm                    # Window/session manager
    waybar                  # Status bar for Wayland compositors
    wl-clipboard            # Clipboard utilities for Wayland
    xdg-desktop-portal-gtk  # XDG portal for GTK apps
    xdg-desktop-portal-hyprland # XDG portal for Hyprland
    xdg-user-dirs           # User directories management

    # ---------- Appearance / Fonts / Icons / Cursors -----------
    capitaine-cursors       # Cursor theme
    noto-fonts              # Noto font family
    otf-font-awesome        # Font Awesome icons
    kvantum                 # Qt theming engine
    ttf-caladea             # Caladea font
    ttf-cascadia-mono-nerd  # Cascadia Mono Nerd Font
    ttf-dejavu              # DejaVu fonts
    ttf-roboto-mono-nerd    # Roboto Mono Nerd Font

    # ----------- KDE Applications --------------
    ark                     # Archive manager
    dolphin                 # KDE file manager
    filelight               # Disk usage viewer
    gwenview                # KDE image viewer
#    haruna                  # Music player
#    kamoso                  # Webcam app
#    ksystemlog              # KDE log viewer
    kio-admin               # KDE admin tools helper
    kdeconnect              # Device integration

    # --------- Databases / SQL / Data Tools ----------
#    dbeaver                 # SQL GUI client
#    csvkit                  # CSV tools
#    miller                  # CSV processor
#    mariadb-libs            # MariaDB client libraries
#    mariadb-lts             # MariaDB server (long-term support)

    # ------------ Multimedia --------------
#    gimp                    # Image editor
#    graphicsmagick          # Image processing tools
#    gst-libav               # GStreamer plugin for libav
#    gst-plugin-mp4          # GStreamer MP4 plugin
#    handbrake               # Video transcoder
#    inkscape                # Vector graphics editor
#    playerctl               # Control media players from CLI
#    qt6-multimedia-ffmpeg   # Qt multimedia plugins

    # ----------- CLI environment -------------
    alacritty               # GPU-accelerated terminal
#    bash-completion
#    bat-extras              # Extra tools for bat (cat clone)
    fzf                     # Fuzzy finder
#    eza
#    less                    # File pager
#    navi                    # Interactive cheatsheets
#    skim                    # Fuzzy finder (alternative to fzf)
    starship                # Shell prompt
#    zellij                  # Terminal workspace manager
    zsh-autocomplete        # Zsh autocomplete plugin
    zsh-completions         # Zsh completions
    zsh-syntax-highlighting # Zsh syntax highlighting

    # ------------ CLI Script tools ------------
#    aria2                   # Download utility
#    batched                 # Batch command execution
#    choose                  # CLI selector
#    dasel                   # YAML/JSON/TOML query/update tool
    fd                      # Fast file search
#    grex                    # Regex generator
    parallel                # Parallel command runner
    pv                      # Pipe viewer
    sd                      # Sed alternative (easy find/replace)
#    trash-cli               # Trash management CLI
#    wget                    # Network downloader
#    xh                      # Curl alternative
#    xmlstarlet              # Manipulating XML files.
    yq                      # YAML processor

    # ------------ GUI Non-KDE ----------------
#    gnucash                 # Personal finance manager
#    gnumeric                # Spreadsheet app
#    hledger                 # Accounting tool
#    qbittorrent             # Qt BitTorrent client
#    qalculate-qt            # Calculator app (Qt)

    # ---------- Console Applications ---------------
#    fdupes                  # Find duplicate files
#    git-delta               # Git diff viewer
    github-cli              # GitHub CLI tool
    lazygit                 # Git TUI client
#    plocate                 # Locate alternative
#    remind                  # Reminder and calendar program.
    stow                    # Symlink farm manager
    zoxide                  # Smarter cd alternative
#    watchexec
#    visidata                # Interactive data exploration

    # ---------- Shell / Scripting Enhancements -----------
#    expac                   # Query pacman database
#    pacutils                # Pacman helper tools
#    pacman-contrib          # Pacman extras (paccache, checkupdates)
#    rebuild-detector        # Detect package rebuilds
#    run-parts               # For cron jobs

    # --------- Programming / Dev Tools -------------
#    ccache                  # Compiler caching
#    clang                   # C/C++ compiler
#    eslint                  # JavaScript linter
    lua-sec                 # SSL support for Lua
    luarocks                # Lua package manager
    mise                    # Version/environment manager
    neovim-lspconfig        # LSP config for Neovim
#    python-mysqlclient      # MySQL client for Python
#    python-polars           # Dataframe library
#    python-pandas           # Data analysis library
#    python-plotly           # Interactive visualization library
#    python-xlsxwriter       # Excel writing library
#    pyright                 # Python, find common bugs and enforce type hints.
#    shfmt                   # Shell script formatter
#    rust-analyzer           # Rust language server
#    tree-sitter-bash        # Bash grammar for tree-sitter
#    tree-sitter-python      # Python grammar for tree-sitter
#    uv
    zed                     # A high-performance, collaborative code editor.

    # ----------- Spell Checking / Hyphenation --------------
    hunspell-en_us          # English spell checker
    hyphen-en               # English hyphenation patterns

    # ---------------- Games ----------------
#    gamemode                # Gaming performance tool
#    gnuchess                # Chess engine
#    lib32-gamemode          # 32-bit GameMode support
#    lib32-mangohud          # 32-bit performance overlay
#    lutris                  # Game manager
#    mangohud                # Performance overlay
#    mgba-qt                 # Game Boy Advance emulator (Qt frontend)
#    pychess
#    steam-native-runtime    # Steam runtime for native games
#    umu-launcher            # A lightweight and simple application launcher.
#    vkd3d                   # Vulkan-based Direct3D 12 translation layer
#    wine-staging            # Wine with staging patches
#    wine-mono               # Mono runtime for Wine
#    winetricks              # Wine helper scripts

    # ------------ Miscellaneous / Other Tools --------------
    tesseract-data-eng      # OCR data
    unarchiver              # Archive extraction tool
    yt-dlp                  # Youtube downloader

    # ------------ Chaotic-Aur --------------
#    anki
#    betterbird-bin
#    dxvk-mingw-git
    brave-bin
    logiops
#    localsend
#    ocrmypdf
    octopi
#    onlyoffice-bin
    paru
#    proton-ge-custom-bin
    qt6ct-kde
#    rpcs3-git
#    zapzap
    zsh-vi-mode
)

# ──────────────── AUR ──────────────── #
AUR=(
    ayugram-desktop-bin
    mycli
#    python-yfinance
#    surfshark-client
#    wl-screenrec
    walker-bin
)
