### Partitioning
d-i partman-auto/disk string /dev/sda
d-i partman-auto/method string regular
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-auto/choose_recipe select atomic

# This makes partman automatically partition without confirmation
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# Locale
d-i debian-installer/locale string @@VBOX_INSERT_LOCALE@@
d-i console-setup/ask_detect boolean false
d-i console-setup/layoutcode string us
d-i keyboard-configuration/xkb-keymap select us

# Network
d-i netcfg/get_hostname string @@VBOX_INSERT_HOSTNAME_WITHOUT_DOMAIN@@
d-i netcfg/get_domain string @@VBOX_INSERT_HOSTNAME_DOMAIN@@
d-i netcfg/choose_interface select auto

# Clock
@@VBOX_COND_IS_RTC_USING_UTC@@
d-i clock-setup/utc-auto boolean true
d-i clock-setup/utc boolean true
@@VBOX_COND_END@@
@@VBOX_COND_IS_NOT_RTC_USING_UTC@@
d-i clock-setup/utc-auto boolean false
d-i clock-setup/utc boolean false
@@VBOX_COND_END@@
d-i time/zone string @@VBOX_INSERT_TIME_ZONE_UX@@
@@VBOX_COND_IS_INSTALLING_ADDITIONS@@d-i clock-setup/ntp boolean false@@VBOX_COND_END@@
@@VBOX_COND_IS_NOT_INSTALLING_ADDITIONS@@d-i clock-setup/ntp boolean true@@VBOX_COND_END@@

# Packages, Mirrors, Image
d-i base-installer/kernel/override-image string linux-image-amd64
d-i pkgsel/install-language-support boolean false

@@VBOX_COND_AVOID_UPDATES_OVER_NETWORK@@
d-i apt-setup/use_mirror boolean false
d-i apt-setup/services-select multiselect updates
d-i netcfg/no_default_route true
d-i netcfg/get_nameservers ""
@@VBOX_COND_ELSE@@
d-i apt-setup/use_mirror boolean true
d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string
@@VBOX_COND_IS_INSTALLING_ADDITIONS@@
d-i pkgsel/include string bash build-essential dkms linux-headers-amd64
@@VBOX_COND_END@@
@@VBOX_COND_END@@

@@VBOX_COND_IS_MINIMAL_INSTALLATION@@
tasksel tasksel/first multiselect standard
d-i pkgsel/include string openssh-server
d-i pkgsel/upgrade select none
@@VBOX_COND_END@@

# Users
d-i passwd/user-fullname string @@VBOX_INSERT_USER_FULL_NAME@@
d-i passwd/username string @@VBOX_INSERT_USER_LOGIN@@
d-i passwd/user-password-crypted password @@VBOX_INSERT_USER_PASSWORD_SHACRYPT512@@
@@VBOX_COND_IS_ROOT_PASSWORD_SET@@
d-i passwd/root-login boolean true
d-i passwd/root-password-crypted password @@VBOX_INSERT_ROOT_PASSWORD_SHACRYPT512@@
@@VBOX_COND_ELSE@@
d-i passwd/root-login boolean false
@@VBOX_COND_END@@
d-i passwd/user-default-groups string sudo

# Grub
d-i grub-installer/grub2_instead_of_grub_legacy boolean true
d-i grub-installer/only_debian boolean true

# Due notably to potential USB sticks, the location of the MBR can not be
# determined safely in general, so this needs to be specified:
#d-i grub-installer/bootdev  string /dev/sda
# To install to the first device (assuming it is not a USB stick):
d-i grub-installer/bootdev  string default

d-i finish-install/reboot_in_progress note

# Custom Commands.
# Note! Debian netboot images use busybox, so no bash.
#       Tell script to use target bash.
d-i preseed/late_command string cp /cdrom/vboxpostinstall.sh /target/root/vboxpostinstall.sh \
 && chmod +x /target/root/vboxpostinstall.sh \
 && /bin/sh /target/root/vboxpostinstall.sh --need-target-bash --preseed-late-command
