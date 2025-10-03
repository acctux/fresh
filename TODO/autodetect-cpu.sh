
CPU_MAN=""

autodetect_cpu() {
    init_pkgs=(
    base \
    base-devel \
    btrfs-progs \
    efibootmgr \
    linux \
    linux-firmware \
    neovim-lspconfig \
    reflector \
    zram-generator
    )
    cpu_type=$(lscpu)
    if grep -E "AuthenticAMD" <<< ${cpu_type}; then
        init_pkgs+=(amd-ucode)
        CPU_MAN="amd"
    elif grep -E "GenuineIntel" <<< ${cpu_type}; then
        init_pkgs+=(intel-ucode)
        CPU_MAN="intel"
    fi
    echo "Detectcted: $CPU_MAN"
    echo "$init_pkgs"
    pacstrap "/mnt" "${init_pkgs[@]}"
}
