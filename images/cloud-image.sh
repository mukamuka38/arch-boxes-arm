#!/bin/bash
# shellcheck disable=SC2034,SC2154
IMAGE_NAME="Arch-Linux-aarch64-cloudimg-${build_version}.qcow2"
DISK_SIZE=""
# The growpart module[1] requires the growpart program, provided by the
# cloud-guest-utils package
# [1] https://cloudinit.readthedocs.io/en/latest/topics/modules.html#growpart
PACKAGES=(check parted json-glib curl libyaml sudo openssh sshfs cloud-guest-utils)
SERVICES=(cloud-init-local.service cloud-init.service cloud-config.service cloud-final.service sshd.service)

function pre() {
  pushd "${TMPDIR}"
  asp checkout cloud-init
  pushd cloud-init/trunk
  chown -R $SUDO_USER .
  sudo -u $SUDO_USER sed -i 's/netplan //g' PKGBUILD
  sudo -u $SUDO_USER ls -alh .
  sudo -u $SUDO_USER makepkg -s --asdeps --nocheck --noconfirm
  PACKAGE=$(find * -type f -name 'cloud-init*.pkg.tar.*')
  cp "${PACKAGE}" "${MOUNT}/var/cache/pacman/"

  arch-chroot "${MOUNT}" /bin/bash -e <<EOF
  pacman -U "/var/cache/pacman/${PACKAGE}" --noconfirm
EOF
  popd
  popd
}

function post() {
  qemu-img convert -c -f raw -O qcow2 "${1}" "${2}"
  rm "${1}"
}
