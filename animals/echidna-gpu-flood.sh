init -a flood_pkgs="${FLOOD_PAC[@]}"

identify_gpu
    gpu_type=$(lspci)
    if grep -E "NVIDIA|GeForce" <<< "${gpu_type}"; then
        if grep -E "Radeon" <<< "${gpu_type}"; then
            flood_pkgs+=(nvidia-prime)
        fi
        pkgs+=(nvidia-open-dkms dkms linux-headers libva-nvidia-driver libxnvctrl)
    fi
    if grep -E "Radeon" <<< "${gpu_type}"; then
        flood_pkgs+=(mesa mesa-utils vulkan-radeon libva-mesa-driver)
    fi
    if grep -E "Integrated Graphics Controller" <<< "${gpu_type}"; then
        flood_pkgs+=(libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-utils lib32-mesa)
    fi

    if [ ${#flood_pkgs[@]} -gt 0 ]; then
        pacman -S --noconfirm --needed "${flood_pkgs[@]}"
    else
        echo "GPU not identified."
    fi
}

dog() {
    identify_gpu
    pacman -S --needed "${flood_pkgs[@]}"
}
