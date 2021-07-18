#!/bin/bash

BLACK="\e[0;30m"
RED="\e[0;31m"
GREEN="\e[0;32m"
YELLOW="\e[0;33m"
BLUE="\e[0;34m"
PURPLE="\e[0;35m"
CYAN="\e[0;36m"
WHITE="\e[0;37m"

BOLD_BLACK="\e[1;30m"
BOLD_RED="\e[1;31m"
BOLD_GREEN="\e[1;32m"
BOLD_YELLOW="\e[1;33m"
BOLD_BLUE="\e[1;34m"
BOLD_PURPLE="\e[1;35m"
BOLD_CYAN="\e[1;36m"
BOLD_WHITE="\e[1;37m"
RESET="\e[0m"

file=`basename "$0"`
path=`dirname "$0"`

function chroot() {
	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Time zone${RESET}"
	ls /usr/share/zoneinfo
	echo -e "${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Enter the name of your region:${RESET}"
	read region
	echo -e "\n"

	ls /usr/share/zoneinfo/${region}
	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Enter the name of your city or province:${RESET}"
	read time_zone
	echo -e "\n"

	ln -sf /usr/share/zoneinfo/${region}/${time_zone} /etc/localtime
	hwclock --systohc

	sed -e "s|#  en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|g" -i /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf

	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Enter a hostname:${RESET}"
	read arch_hostname
	arch_hostname=${arch_hostname,,}
	echo "$arch_hostname" > /etc/hostname

	echo "127.0.0.1	localhost
	::1		localhost" > /etc/hosts

	echo -e "\n"

	mkinitcpio -P

	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Set a root password${RESET}\n"
	passwd

	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Installing a bootloader...${RESET}\n"
	pacman -Sy grub efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
	grub-mkconfig -o /boot/grub/grub.cfg

	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Network settings${RESET}\n"
	systemctl start systemd-networkd
	systemctl start systemd-resolved
	networkctl list

	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Enter a network device name (For example: enp1s0):${RESET} "
	read network_device_name
	network_device_name=${network_device_name,,}

	echo "[Match]
	Name=${network_device_name}

	[Network]
	DHCP=yes" > /etc/systemd/network/20-wired.network

	systemctl enable systemd-networkd
	systemctl enable systemd-resolved

	echo "sh /${file} -t" > /root/.bash_profile

	echo -e "\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Please restart the system. Enter this command: reboot${RESET}"

	exit
}

function arch() {
	ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Add a user${RESET}"
	echo -e "${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Enter a username:${RESET}"
	read username
	username=${username,,}

	useradd -g users -G	wheel,storage,power -m $username

	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Enter a password for the user '$username'\n${RESET}"
	passwd $username

	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Add a privileges to $username\n${RESET}"
	sleep 5
	visudo

	echo -e "\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Installing all necessary packages for the Dekstop Enviroment or Window Manager...\n${RESET}"

	pacman xorg -Sy xorg-server xorg-xinit libx11 libxinerama libxft webkit2gtk git alsa-utils pulseaudio pavucontrol noto-fonts-emoji htop neofetch

	echo -e "${BOLD_GREEN}\n>${BOLD_RED}>${BOLD_WHITE} Do you want to install
${BOLD_BLUE}1) ${BOLD_GREEN}Desktop Enviroment
${BOLD_BLUE}2) ${BOLD_GREEN}Window Manager

${BOLD_RED}[${BOLD_GREEN}1${BOLD_RED}/${BOLD_GREEN}2${BOLD_RED}]:${RESET}"
	read GUI

	if [ $GUI = 1 ] || [ $GUI = "1)" ]; then
		 echo -e "\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Which DE do you want to install?
${BOLD_BLUE}1) ${BOLD_GREEN}KDE-Plasma
${BOLD_BLUE}2) ${BOLD_GREEN}XFCE4
${BOLD_BLUE}3) ${BOLD_GREEN}GNOME

${BOLD_RED}[${BOLD_GREEN}1${BOLD_RED}/${BOLD_GREEN}2${BOLD_RED}/${BOLD_GREEN}3${BOLD_RED}]:${RESET}"
	  read DE

	  if [ $DE = 1 ] || [ $DE = "1)" ]; then
			pacman -Sy --needed sddm
			pacman -Sy --needed kde-applications
			systemctl enable sddm
			systemctl enable NetworkManager
			reboot
	  elif [ $DE = 2 ] || [ $DE = "2)" ]; then
			pacman -Sy xfce4 xfce4-goodies lightdm lightdm lightdm-gtk-greeter
			systemctl enable lightdm
		elif [ $DE = 3 ] || [ $DE = "3)" ]; then
			pacman -Sy xorg-twm xorg-xclock xterm
			pacman -Sy ttf-dejavu
			pacman -Sy gnome
			pacman -Sy lxterminal		
			systemctl enable gdm.service
			systemctl enable NetworkManager
		fi

	elif [ $GUI = 2 ] || [ $GUI = "2)" ]; then
		echo -e "\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Which WM do you want to install?
	${BOLD_BLUE}1) ${BOLD_GREEN}DWM - Dynamic Window Manager
	${BOLD_BLUE}2) ${BOLD_GREEN}i3

	${BOLD_RED}[${BOLD_GREEN}1${BOLD_RED}/${BOLD_GREEN}2${BOLD_RED}]:${RESET}"
		read WM

		if [ $WM = 1 ] || [ $WM = "1)" ]; then
			mkdir dwm
			mkdir st
			git clone https://git.suckless.org/dwm /home/$username/dwm/
			git clone https://git.suckless.org/st /home/$username/st/
			echo "exec dwm" > /home/$username/.xinitrc
			cd /home/$username/st/ && make clean install
			cd /home/$username/st/ && make clean install
			sed -i "s|/bin/sh|/usr/local/bin/st|" /home/$username/dwm/config.h
			cd /home/$username/dwm/ && make clean install
		elif [ $WM = 2 ] || [ $WM = "2)" ]; then
			pacman -Sy i3
			echo "exec i3" > /home/$username/.xinitrc
		fi
	fi

	rm /root/.bash_profile
	rm /${file}
	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Bye!!!\n\n${RESET}"

	exit
}

function format_disk() {
	echo -e "\n${BOLD_GREEN}>${BOLD_RED}> ${BOLD_WHITE}Choose the drive which you want to format (For example: /dev/sda):${RESET} "
	read disk_choice
	disk_choice=${disk_choice,,}
}

if [ $# -eq 1 ]; then
	arg="$1"

	if [ $arg = "-s" ]; then
		chroot
	elif [ $arg = "-t" ]; then
		arch
	fi
fi

echo -e "\n\n${BOLD_WHITE}¸„.-•~¹°”ˆ˜¨ >>> ${BOLD_BLUE}Arch Linux Installer ${BOLD_GREEN}v1.0 by ${BOLD_RED}ProX${BOLD_WHITE} <<< ¨˜ˆ”°¹~•-.„¸${RESET}\n\n\n"

timedatectl set-ntp true

echo -e "\n${BOLD_GREEN}>${BOLD_RED}> ${BOLD_WHITE}Disk info${RESET}:\n"
lsblk

format_disk

echo -e "${BOLD_GREEN}\n>${BOLD_RED}> ${BOLD_WHITE}Do you want to format the '${disk_choice}' drive? ${BOLD_RED}[${BOLD_GREEN}Y${BOLD_RED}/${BOLD_GREEN}n${BOLD_RED}]:${RESET} "
read confirm_disk_choice
confirm_disk_choice=${confirm_disk_choice,,}

if [ $confirm_disk_choice = "y" ] || [ $confirm_disk_choice = "yes" ] || [ -z $confirm_disk_choice ]; then
	cgdisk $disk_choice
else
	echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}> ${BOLD_WHITE}Do you want to choose the disk again? ${BOLD_RED}[${BOLD_GREEN}Y${BOLD_RED}/${BOLD_GREEN}n${BOLD_RED}]:${RESET} "
	read choose_disk_again
	choose_disk_again=${choice_disk_again,,}

	if [ $choose_disk_again = "y" ] || [ $choose_disk_again = "yes" ] || [ -z $choose_disk_again ]; then
		format_disk
	else
		echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Bye!!!${RESET}\n\n"
		exit
	fi
fi

lsblk

echo -e "\n${BOLD_GREEN}>${BOLD_RED}> ${BOLD_WHITE}Please enter the name of the boot partition (For example: /dev/sda1):${RESET}"
read boot_partition
boot_partition=${boot_partition,,}

mkfs.fat -F32 $boot_partition

echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}> ${BOLD_WHITE}Do you have a swap partition? ${BOLD_RED}[${BOLD_GREEN}Y${BOLD_RED}/${BOLD_GREEN}n${BOLD_RED}]:${RESET}"
read swap
swap=${swap,,}

if [ $swap = "y" ] || [ $swap = "yes" ] || [ -z $swap ]; then
	echo -e "\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Please enter the name of the swap partition (For example: /dev/sda2):${RESET}"
	read swap_partition
	swap_partition=${swap_partition,,}

	mkswap $swap_partition
	swapon $swap_partition
fi

echo -e "\n\n${BOLD_GREEN}>${BOLD_RED}>${BOLD_WHITE} Please enter the name of the root partition (For example: /dev/sda3):${RESET} "
read root_partition
root_partition=${root_partition,,}

mkfs.ext4 $root_partition

mount $root_partition /mnt
mkdir -p /mnt/boot/
mount $boot_partition /mnt/boot

pacstrap /mnt base linux linux-firmware base-devel vi nano vim man-db sudo wget
genfstab -U /mnt >> /mnt/etc/fstab

cp ${path}/${file} /mnt/

arch-chroot /mnt /${file} -s
