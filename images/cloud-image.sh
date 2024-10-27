#!/bin/bash
# shellcheck disable=SC2034,SC2154
IMAGE_NAME="Arch-Linux-aarch64-cloudimg-${build_version}.qcow2"
DISK_SIZE=""
# The growpart module[1] requires the growpart program, provided by the
# cloud-guest-utils package
# [1] https://cloudinit.readthedocs.io/en/latest/topics/modules.html#growpart
PACKAGES=(parted sudo openssh sshfs cloud-guest-utils)
SERVICES=(cloud-init-main.service cloud-init-local.service cloud-init-network.service cloud-config.service cloud-final.service sshd.service)

function pre() {
  local CLOUD_INIT_PACKAGE=`curl -fs https://archive.archlinux.org/packages/c/cloud-init/ | grep -Eo 'cloud-init-[0-9]{2}(\.[0-9]*)*-[0-9]*-any.pkg.tar.zst' | tail -n 1`
  curl -f  https://archive.archlinux.org/packages/c/cloud-init/${CLOUD_INIT_PACKAGE} -o ${MOUNT}/var/cache/pacman/${CLOUD_INIT_PACKAGE}
  arch-chroot "${MOUNT}" /usr/bin/pacman -U --noconfirm /var/cache/pacman/${CLOUD_INIT_PACKAGE}
}

function post() {
  qemu-img convert -c -f raw -O qcow2 "${1}" "${2}"
  rm "${1}"
}
