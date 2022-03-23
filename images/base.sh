#!/bin/bash

# Misc "tweaks" done after bootstrapping
function pre() {
  # Remove machine-id see:
  # https://gitlab.archlinux.org/archlinux/arch-boxes/-/issues/25
  # https://gitlab.archlinux.org/archlinux/arch-boxes/-/issues/117
  rm "${MOUNT}/etc/machine-id"

  arch-chroot "${MOUNT}" /usr/bin/btrfs subvolume create /swap
  chattr +C "${MOUNT}/swap"
  chmod 0700 "${MOUNT}/swap"
  fallocate -l 512M "${MOUNT}/swap/swapfile"
  chmod 0600 "${MOUNT}/swap/swapfile"
  mkswap "${MOUNT}/swap/swapfile"
  echo -e "/swap/swapfile none swap defaults 0 0" >>"${MOUNT}/etc/fstab"

  sed -i -e 's/^#\(en_US.UTF-8\)/\1/' "${MOUNT}/etc/locale.gen"
  arch-chroot "${MOUNT}" /usr/bin/locale-gen
  arch-chroot "${MOUNT}" /usr/bin/systemd-firstboot --locale=en_US.UTF-8 --timezone=UTC --hostname=archlinux --keymap=us
  ln -sf /run/systemd/resolve/stub-resolv.conf "${MOUNT}/etc/resolv.conf"

  # Setup pacman-init.service for clean pacman keyring initialization
  cat <<EOF >"${MOUNT}/etc/systemd/system/pacman-init.service"
[Unit]
Description=Initializes Pacman keyring
Before=sshd.service cloud-final.service
ConditionFirstBoot=yes

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/pacman-key --init
ExecStart=/usr/bin/pacman-key --populate archlinuxarm

[Install]
WantedBy=multi-user.target
EOF

  # enabling important services
  arch-chroot "${MOUNT}" /bin/bash -e <<EOF
source /etc/profile
systemctl enable sshd
systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd
systemctl enable pacman-init.service
EOF

  ROOT_UUID="$(findmnt -fn -o UUID "${MOUNT}")"
  BOOT_UUID="$(findmnt -fn -o UUID "${MOUNT}/boot")"
  cat <<EOF >"${MOUNT}/etc/fstab"
/dev/disk/by-uuid/${ROOT_UUID} / btrfs defaults 0 0
/dev/disk/by-uuid/${BOOT_UUID} /boot vfat defaults 0 0
EOF
  cat <<EOF >"${MOUNT}/boot/startup.nsh"
Image root=UUID=${ROOT_UUID} rw initrd=\initramfs-linux.img
EOF
}
