#!/bin/bash

echo -e "Arch Linux on a usb key \n"

echo -e "Devices \n"
lsblk
read -p "Enter the name of your interested path (Example : sda) : " sd
echo -e "Done \n"

echo -e "Partition table \n"
echo -e "Boot > 500M > \"Bootable\""
echo -e "Home > the rest"
echo -e "Don't forget to write and save"
read -p "Press enter to continue"
cfdisk /dev/$sd
echo -e "Done \n"

echo -e "Format \n"
lsblk
sd1=$sd\1
echo -e "Format \"Boot\""
mkfs.ext4 -O "^has_journal" /dev/$sd1
echo -e "Format \"Home\""
sd2=$sd\2
mkfs.ext4 -O "^has_journal" /dev/$sd2
echo -e "Done \n"

echo -e "Mount \n"
echo -e "Mount \"/mnt\""
mount /dev/$sd2 /mnt
mkdir /mnt/boot
mkdir /mnt/home
echo -e "Mount \"/mnt/boot\""
mount /dev/$sd1 /mnt/boot
echo -e "Mount \"/mnt/home\""
mount /dev/$sd2 /mnt/home
echo -e "Done \n"

echo -e "Mirrorlist \n"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
echo -e "Done \n"

echo -e "Base package \n"
pacstrap -i /mnt base base-devel
echo -e "Done \n"

echo -e "Fstab \n"
genfstab -U -p /mnt >> /mnt/etc/fstab
echo -e "Done \n"

echo -e "Chroot \n"
arch-chroot /mnt /bin/bash
echo -e "Done /n"

echo -e "Language \n"
echo -e "Uncomment en_US.UTF-8"
read -p "Press enter to continue"
nano /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo -e "Done \n"

echo -e "Time \n"
ln -s /usr/share/zoneinfo/Europe/Paris > /etc/localtime
hwclock --systohc --utc

echo -e "Hostname \n"
read -p "Enter a hostname : " hostnm
echo $hostnm > /etc/hostname
echo -e "Done \n"

echo -e "Pacman & Yaourt \n"
echo -e "Uncomment \"[multilib]\" and the next line"
read -p "Press enter to continue"
nano /etc/pacman.conf
echo -e "[archlinuxfr]" >> /etc/pacman.conf
echo -e "SigLevel = Never" >> /etc/pacman.conf
echo -e "Server = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf
echo -e "Update \"Pacman\" \n"
pacman -Sy
echo -e "Install \"Yaourt\" \n"
pacman -S yaourt
echo -e "Install \"Bash-completion\" \n"
pacman -S bash-completion
echo -e "Install \"Iw\", \"Wpa-supplicant\" and \"Dialog\" \n"
pacman -S iw wpa-supplicant dialog
echo -e "Done \n"

echo -e "Users \n"
echo -e "Set root's password"
read -p "Press enter to continue"
passwd
echo -e "Creation of the user"
read -p "Enter a hostname : " usr
useradd -m -g users -G wheel,storage,power -s /bin/bash $usr
echo -e "Set user's password"
read -p "Press enter to continue"
passwd $usr

echo -e "Visudo \n"
echo -e "Uncomment \"%wheel ALL=(ALL) ALL\" and add \"Defaults rootpw\" just after the uncommented line"
read -p "Press enter to continue"
EDITOR=nano visudo
echo -e "Done \n"

echo -e "Mkinitcpio \n"
echo -e "Write \"block\" before \"autodetect\" and remove the other \"block\""
echo -e "It should end up like that : HOOKS=\"base udev block autodetect modconf filesystems keyboard fsck\""
read -p "Press enter to continue"
nano /etc/mkinitcpio.conf
mkinitcpio -p linux
echo -e "Done \n"

echo -e "Grub \n"
pacman -S grub
grub-install --boot-directory=/boot --recheck --debug --target=i386-pc /dev/$sd
read -r -p "Did it fail ? [Y/n]" response
response=${response,,} # tolower
if [[ $response =~ ^(yes|y| ) ]]; then
	grub-install --boot-directory=/boot --recheck --debug --force --target=i386-pc /dev/$sd
fi
grub-mkconfig -o /boot/grub/grub.cfg
cd /boot/grub
uuid=`blkid -o value -s UUID /dev/$sd2` 
echo -e "LABEL Arch" >> menu.lst
echo -e "    MENU LABEL Arch Linux" >> menu.lst
echo -e "    LINUX ../vmlinuz-linux" >> menu.lst
echo -e "    APPEND root=UUID=$uuid ro" >> menu.lst
echo -e "    INITRD ../initramfs-linux.img" >> menu.lst
echo -e "Done \n"

exit
umount -R /mnt
echo -e "Reboot \n"
reboot
