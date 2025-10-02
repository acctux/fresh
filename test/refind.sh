archrefindinstall(){
	clear

	echo "pacstrap /mnt refind"
	echo "archchroot refindbootloaderinstall ${realrootdev}"
	echo "echo \"\\\"Arch Linux         \\\" \\\"root=UUID=${rootuuid} rw add_efi_memmap\\\"\" > /mnt/boot/refind_linux.conf"
	echo "echo \"\\\"Arch Linux Fallback\\\" \\\"root=UUID=${rootuuid} rw add_efi_memmap initrd=/initramfs-linux-fallback.img\\\"\" >> /mnt/boot/refind_linux.conf"
	echo "echo \"\\\"Arch Linux Terminal\\\" \\\"root=UUID=${rootuuid} rw add_efi_memmap systemd.unit=multi-user.target\\\"\" >> /mnt/boot/refind_linux.conf"

	pacstrap /mnt refind-efi
	archchroot refindbootloaderinstall ${realrootdev}
	rootuuid=$(blkid -s UUID -o value ${realrootdev})
	echo "\"Arch Linux         \" \"root=UUID=${rootuuid} rw add_efi_memmap\"" > /mnt/boot/refind_linux.conf
	echo "\"Arch Linux Fallback\" \"root=UUID=${rootuuid} rw add_efi_memmap initrd=/initramfs-linux-fallback.img\"" >> /mnt/boot/refind_linux.conf
	echo "\"Arch Linux Terminal\" \"root=UUID=${rootuuid} rw add_efi_memmap systemd.unit=multi-user.target\"" >> /mnt/boot/refind_linux.conf
	pressanykey
}
archrefindinstallchroot(){
	#--usedefault /dev/sdXY --alldrivers
	echo "refind-install"
	refind-install
	isvbox=$(lspci | grep "VirtualBox G")
	if [ "${isvbox}" ]; then
		echo "VirtualBox detected, creating startup.nsh..."
		echo "\EFI\refind\refind_x64.efi" > /boot/startup.nsh
	fi
}
