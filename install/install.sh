#!/bin/bash
set -e

echo "[*] Enabling NTP..."
timedatectl set-ntp true

echo "[*] Partitioning disk..."
(
echo g
echo n
echo
echo
echo
echo +512M
echo t
echo 1
echo n
echo
echo
echo
echo
echo w
) | fdisk /dev/sda

echo "[*] Formatting partitions..."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2

echo "[*] Mounting partitions..."
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

echo "[*] Installing base system..."
pacstrap /mnt base linux linux-firmware networkmanager sudo nano grub os-prober

echo "[*] Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "[*] Chrooting into system..."
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "archvm" > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\tarchvm.localdomain\tarchvm" > /etc/hosts

# Root password
echo root:strixed | chpasswd

# Add user StrixedARCH
useradd -m -G wheel StrixedARCH
echo StrixedARCH:strixed | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

systemctl enable NetworkManager

# Bootloader
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# KDE + essentials + kitty terminal
pacman -Sy --noconfirm xorg plasma sddm konsole dolphin firefox kitty

systemctl enable sddm
EOF

echo "[*] Unmounting and rebooting..."
umount -R /mnt
reboot
