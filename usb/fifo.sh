#!/bin/bash
#wget -O fifo.sh goo.gl/LaQnYp && bash fifo.sh

echo -e "\nArch Linux on an usb key"

echo -e "\nDevices"
lsblk
read -p "Enter the name of your interested path (Example : sda) : " sd

echo -e "\nPartition table"
echo -e "Boot > 500M > \"Bootable\""
echo -e "Home > the rest"
echo -e "Don't forget to write and save"
read -p "Press enter to continue"
cfdisk /dev/$sd

echo -e "\nFormat"
lsblk
sd1=$sd\1
echo -e "Format \"Boot\""
mkfs.ext4 -O "^has_journal" /dev/$sd1
echo -e "Format \"Home\""
sd2=$sd\2
mkfs.ext4 -O "^has_journal" /dev/$sd2

echo -e "Mount"
echo -e "Mount \"/mnt\""
mount /dev/$sd2 /mnt
mkdir /mnt/boot
mkdir /mnt/home
echo -e "Mount \"/mnt/boot\""
mount /dev/$sd1 /mnt/boot
echo -e "Mount \"/mnt/home\""
mount /dev/$sd2 /mnt/home

echo -e "\nMirrorlist"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

echo -e "\nBase package"
pacstrap -i /mnt base base-devel

echo -e "\nFstab"
genfstab -U -p /mnt >> /mnt/etc/fstab

echo -e "\nLanguage"
echo -e "Uncomment en_US.UTF-8"
read -p "Press enter to continue"
arch-chroot /mnt nano /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo LANG=en_US.UTF-8 > /etc/locale.conf

echo -e "\nTime"
arch-chroot /mnt ln -s /usr/share/zoneinfo/Europe/Paris > /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

echo -e "\nHostname"
read -p "Enter a hostname : " hostnm
arch-chroot /mnt echo $hostnm > /etc/hostname

echo -e "\nPacman & Yaourt"
echo -e "Uncomment \"[multilib]\" and the next line"
read -p "Press enter to continue"
arch-chroot /mnt nano /etc/pacman.conf
arch-chroot /mnt echo -e "[archlinuxfr]" >> /etc/pacman.conf
arch-chroot /mnt echo -e "SigLevel = Never" >> /etc/pacman.conf
arch-chroot /mnt echo -e "Server = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf
echo -e "Update \"Pacman\" \n"
arch-chroot /mnt pacman -Sy
echo -e "Install \"Yaourt\" \n"
arch-chroot /mnt pacman -S yaourt
echo -e "Install \"Bash-completion\" \n"
arch-chroot /mnt pacman -S bash-completion
echo -e "Install \"Iw\", \"Wpa_supplicant\" and \"Dialog\" \n"
arch-chroot /mnt pacman -S iw wpa_supplicant dialog

echo -e "\nUsers"
echo -e "Set root's password"
read -p "Press enter to continue"
arch-chroot /mnt passwd
echo -e "Creation of the user"
read -p "Enter a hostname : " usr
arch-chroot /mnt useradd -m -g users -G wheel,storage,power -s /bin/bash $usr
echo -e "Set user's password"
read -p "Press enter to continue"
arch-chroot /mnt passwd $usr

echo -e "\nVisudo"
echo -e "Uncomment \"%wheel ALL=(ALL) ALL\" and add \"Defaults rootpw\" just after the uncommented line"
read -p "Press enter to continue"
arch-chroot /mnt EDITOR=nano visudo

echo -e "\nMkinitcpio"
echo -e "Write \"block\" before \"autodetect\" and remove the other \"block\""
echo -e "It should end up like that : HOOKS=\"base udev block autodetect modconf filesystems keyboard fsck\""
read -p "Press enter to continue"
arch-chroot /mnt nano /etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -p linux

echo -e "\nGrub"
arch-chroot /mnt pacman -S grub
arch-chroot /mnt grub-install --boot-directory=/boot --recheck --debug --target=i386-pc /dev/$sd
read -r -p "Did it fail ? [Y/n]" response
response=${response,,}
if [[ $response =~ ^(yes|y) ]]; then
    arch-chroot /mnt grub-install --boot-directory=/boot --recheck --debug --force --target=i386-pc /dev/$sd
fi
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
uuid=`blkid -o value -s UUID /dev/$sd2` 
arch-chroot /mnt echo -e "LABEL Arch" >> /boot/grub/menu.lst
arch-chroot /mnt echo -e "    MENU LABEL Arch Linux" >> /boot/grub/menu.lst
arch-chroot /mnt echo -e "    LINUX ../vmlinuz-linux" >> /boot/grub/menu.lst
arch-chroot /mnt echo -e "    APPEND root=UUID=$uuid ro" >> /boot/grub/menu.lst
arch-chroot /mnt echo -e "    INITRD ../initramfs-linux.img" >> /boot/grub/menu.lst

umount -R /mnt
echo -e "\nReboot"
reboot
