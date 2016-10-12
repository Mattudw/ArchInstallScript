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

echo `echo -e "Done /n"` >> archChroot.bash

echo `echo -e "Language \n"` >> archChroot.bash
echo `echo -e "Uncomment en_US.UTF-8"` >> archChroot.bash
echo `read -p "Press enter to continue"` >> archChroot.bash
echo `nano /etc/locale.gen` >> archChroot.bash
echo `locale-gen` >> archChroot.bash
echo `echo LANG=en_US.UTF-8 > /etc/locale.conf` >> archChroot.bash
echo `echo -e "Done \n"` >> archChroot.bash

echo `echo -e "Time \n"` >> archChroot.bash
echo `ln -s /usr/share/zoneinfo/Europe/Paris > /etc/localtime` >> archChroot.bash
echo `hwclock --systohc --utc` >> archChroot.bash

echo `echo -e "Hostname \n"` >> archChroot.bash
echo `read -p "Enter a hostname : " hostnm` >> archChroot.bash
echo `echo $hostnm > /etc/hostname` >> archChroot.bash
echo `echo -e "Done \n"` >> archChroot.bash

echo `echo -e "Pacman & Yaourt \n"` >> archChroot.bash
echo `echo -e "Uncomment \"[multilib]\" and the next line"` >> archChroot.bash
echo `read -p "Press enter to continue"` >> archChroot.bash
echo `nano /etc/pacman.conf` >> archChroot.bash
echo `echo -e "[archlinuxfr]" >> /etc/pacman.conf` >> archChroot.bash
echo `echo -e "SigLevel = Never" >> /etc/pacman.conf` >> archChroot.bash
echo `echo -e "Server = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf` >> archChroot.bash
echo `echo -e "Update \"Pacman\" \n"` >> archChroot.bash
echo `pacman -Sy` >> archChroot.bash
echo `echo -e "Install \"Yaourt\" \n"` >> archChroot.bash
echo `pacman -S yaourt` >> archChroot.bash
echo `echo -e "Install \"Bash-completion\" \n"` >> archChroot.bash
echo `pacman -S bash-completion` >> archChroot.bash
echo `echo -e "Install \"Iw\", \"Wpa-supplicant\" and \"Dialog\" \n"` >> archChroot.bash
echo `pacman -S iw wpa-supplicant dialog` >> archChroot.bash
echo `echo -e "Done \n"` >> archChroot.bash

echo `echo -e "Users \n"` >> archChroot.bash
echo `echo -e "Set root's password"` >> archChroot.bash
echo `read -p "Press enter to continue"` >> archChroot.bash
echo `passwd` >> archChroot.bash
echo `echo -e "Creation of the user"` >> archChroot.bash
echo `read -p "Enter a hostname : " usr` >> archChroot.bash
echo `useradd -m -g users -G wheel,storage,power -s /bin/bash $usr` >> archChroot.bash
echo `echo -e "Set user's password"` >> archChroot.bash
echo `read -p "Press enter to continue"` >> archChroot.bash
echo `passwd $usr` >> archChroot.bash

echo `echo -e "Visudo \n"` >> archChroot.bash
echo `echo -e "Uncomment \"%wheel ALL=(ALL) ALL\" and add \"Defaults rootpw\" just after the uncommented line"` >> archChroot.bash
echo `read -p "Press enter to continue"` >> archChroot.bash
echo `EDITOR=nano visudo` >> archChroot.bash
echo `echo -e "Done \n"` >> archChroot.bash

echo `echo -e "Mkinitcpio \n"` >> archChroot.bash
echo `echo -e "Write \"block\" before \"autodetect\" and remove the other \"block\""` >> archChroot.bash
echo `echo -e "It should end up like that : HOOKS=\"base udev block autodetect modconf filesystems keyboard fsck\""` >> archChroot.bash
echo `read -p "Press enter to continue"` >> archChroot.bash
echo `nano /etc/mkinitcpio.conf` >> archChroot.bash
echo `mkinitcpio -p linux` >> archChroot.bash
echo `echo -e "Done \n"` >> archChroot.bash

echo `echo -e "Grub \n"` >> archChroot.bash
echo `pacman -S grub` >> archChroot.bash
echo `grub-install --boot-directory=/boot --recheck --debug --target=i386-pc /dev/$sd` >> archChroot.bash
echo `read -r -p "Did it fail ? [Y/n]" response` >> archChroot.bash
echo `response=${response,,}` >> archChroot.bash
echo `if [[ $response =~ ^(yes|y| ) ]]; then` >> archChroot.bash
echo `   grub-install --boot-directory=/boot --recheck --debug --force --target=i386-pc /dev/$sd` >> archChroot.bash
echo `fi` >> archChroot.bash
echo `grub-mkconfig -o /boot/grub/grub.cfg` >> archChroot.bash
echo `cd /boot/grub` >> archChroot.bash
echo `uuid=`blkid -o value -s UUID /dev/$sd2` ` >> archChroot.bash
echo `echo -e "LABEL Arch" >> menu.lst` >> archChroot.bash
echo `echo -e "    MENU LABEL Arch Linux" >> menu.lst` >> archChroot.bash
echo `echo -e "    LINUX ../vmlinuz-linux" >> menu.lst` >> archChroot.bash
echo `echo -e "    APPEND root=UUID=$uuid ro" >> menu.lst` >> archChroot.bash
echo `echo -e "    INITRD ../initramfs-linux.img" >> menu.lst` >> archChroot.bash
echo `echo -e "Done \n"` >> archChroot.bash

echo `exit` >> archChroot.bash

mv archChroot.bash /mnt
chmod +x /mnt/archChroot.bash
arch-chroot /mnt ./archChroot.bash

umount -R /mnt
echo -e "Reboot \n"
reboot
