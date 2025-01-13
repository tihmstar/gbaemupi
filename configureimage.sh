#!/bin/bash
SCRIPTROOT=$(readlink -f $0 | rev | cut -d '/' -f2- | rev)

function assert () {
    err=$1
    echo "FATAL: $err"
    exit 1
}

### Chroot to the image ###
echo "*** Stage2: Install packages ***"

# Clean caches
arch-chroot /mnt/ /usr/bin/bash -c 'rm -f /var/cache/pacman/pkg/*' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'rm -f /var/lib/pacman/sync/*' || assert

## Install packages
arch-chroot /mnt/ /usr/bin/bash -c 'sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 20/g" /etc/pacman.conf' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'pacman --disable-download-timeout --noconfirm -Suy' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'pacman --disable-download-timeout --noconfirm -S \
                                                    sudo \
                                                    openssh \
                                                    nano \
                                                    i3 \
                                                    dmenu \
                                                    xorg-server \
                                                    alacritty \
                                                    lightdm \
                                                    mgba-qt lua \
                                                    usbutils \
                                                    bluez bluez-utils tmux \
                                                    xorg-xrandr \
                                                    conky \
                                                    networkmanager \
                                                    ' || assert


echo "*** Configure image ***"
## Start services
# arch-chroot /mnt/ /usr/bin/bash -c 'systemctl enable NetworkManager' || assert
# arch-chroot /mnt/ /usr/bin/bash -c 'systemctl enable sshd' || assert

## Allow sudo to be used
arch-chroot /mnt/ /usr/bin/bash -c 'sed -i "s/# %sudo/%sudo/g" /etc/sudoers' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'groupadd sudo' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'groupadd autologin' || assert

## Add eift user
arch-chroot /mnt/ /usr/bin/bash -c 'useradd -G sudo,autologin -ms /bin/bash gba' || assert
arch-chroot /mnt/ /usr/bin/bash -c '(echo "gba";echo "gba") | passwd gba' || assert

## Don't lockout after 3 invalid login attempts
arch-chroot /mnt/ /usr/bin/bash -c 'echo "deny=0" >> /etc/security/faillock.conf' || assert

## Setup system
# Configure mounts based on labels (important because PI3/PI4 are different)
arch-chroot /mnt/ /usr/bin/bash -c 'echo -e "LABEL=piroot\t/\text4\trw,relatime\t0\t1" >> /etc/fstab' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'echo -e "LABEL=PIBOOT\t/boot\tvfat\trw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro\t0\t2" >> /etc/fstab' || assert

# Set hostname
arch-chroot /mnt/ /usr/bin/bash -c 'echo "GBAEMU" > /etc/hostname' || assert

# Configure locale
arch-chroot /mnt/ /usr/bin/bash -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'echo "LANG=en_US.UTF-8" > /etc/locale.conf' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'locale-gen' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'echo "KEYMAP=de-latin1" > /etc/vconsole.conf' || assert


#create swap
echo "*** Creating SWAP ***"
arch-chroot /mnt/ /usr/bin/bash -c 'dd if=/dev/zero bs=10M count=100 of=/swapfile' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'chmod 600 /swapfile' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'mkswap /swapfile' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'echo "/swapfile           	none      	swap      	defaults  	0 0" >> /etc/fstab' || assert

arch-chroot /mnt/ /usr/bin/bash -c 'mkdir /shawazu' || assert


## Install and configure GUI
# echo "*** Installing YAY ***"
# arch-chroot /mnt/ /usr/bin/bash -c 'pacman --disable-download-timeout --noconfirm -S \
#                                                     git fakeroot gcc go make \
                                                    # ' || assert
# arch-chroot /mnt/ /usr/bin/bash -c 'su gba -c "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg" && pacman --noconfirm -U /tmp/yay/yay-*.pkg*' || assert

# arch-chroot /mnt/ /usr/bin/bash -c 'yay --disable-download-timeout --noconfirm -S \
#                                           autoconf \
#                                           automake \
#                                           pkg-config \
#                                           lightdm-mini-greeter \
#                                           ' || assert

arch-chroot /mnt/ /usr/bin/bash -c 'systemctl enable lightdm' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'systemctl enable bluetooth' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'usermod -aG lp gba' || assert



# Copy config files to the image
cp -a ${SCRIPTROOT}/rootfs locrootfs
chown -R 0:0 locrootfs
cp -a locrootfs/* /mnt/ || assert

# Fixup permissions
arch-chroot /mnt/ /usr/bin/bash -c 'chown -R gba /home/gba'

## Cleanup
echo "*** Cleanup image ***"
# Clean caches
arch-chroot /mnt/ /usr/bin/bash -c 'rm -f /var/cache/pacman/pkg/*' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'rm -f /var/lib/pacman/sync/*' || assert

# Clean unneeded files
arch-chroot /mnt/ /usr/bin/bash -c 'rm -rf /usr/include' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'rm -rf /usr/share/man' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'rm -rf /usr/share/doc' || assert
