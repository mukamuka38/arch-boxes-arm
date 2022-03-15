#!/bin/bash
# shellcheck disable=SC2034,SC2154
IMAGE_NAME="Arch-Linux-x86_64-cloudimg-${build_version}.qcow2"
DISK_SIZE=""
# The growpart module[1] requires the growpart program, provided by the
# cloud-guest-utils package
# [1] https://cloudinit.readthedocs.io/en/latest/topics/modules.html#growpart
PACKAGES=(check parted json-glib curl libyaml base-devel)
SERVICES=(ucd.service)

function pre() {
  arch-chroot "${MOUNT}" /bin/bash -e <<EOF
cd /tmp
curl -O -J -L https://github.com/clearlinux/micro-config-drive/releases/download/v45/micro-config-drive-45.tar.xz
tar xvf micro-config-drive-45.tar.xz
cd micro-config-drive-45
./configure
make
make install
cd /tmp
rm -rf /tmp/micro-config-drive-45
systemctl daemon-reload
EOF
}

function post() {
  qemu-img convert -c -f raw -O qcow2 "${1}" "${2}"
  rm "${1}"
}
