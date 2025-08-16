mount -v --bind /dev /mnt/lfs-root/dev
mount -v --bind /dev/pts /mnt/lfs-root/dev/pts
mount -vt proc proc /mnt/lfs-root/proc
mount -vt sysfs sysfs /mnt/lfs-root/sys
mount -vt tmpfs tmpfs /mnt/lfs-root/run
