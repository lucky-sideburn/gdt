#!/bin/bash
# This script prepares a Linux From Scratch (LFS) image for use with KVM/QEMU and Vagrant-To-VirtualBox
# Parse arguments

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --buildmode) BUILD_MODE="$2"; shift ;;
    *) echo "[ERROR] Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

# Validate strategy
if [[ "$BUILD_MODE" != "host_kvm" && "$BUILD_MODE" != "vagrant_vbox" ]]; then
  echo "[ERROR] Invalid strategy: $BUILD_MODE. Allowed values are 'host_kvm' or 'vagrant_vbox'."
  exit 1
fi

echo "[INFO] Using build strategy: $BUILD_MODE"

if [[ "$BUILD_MODE" == "host_kvm" ]]; then
  echo "[INFO] BUILD_MODE is set to host_kvm. Proceeding with KVM-specific setup..."
  IMAGE_PATH="/var/lib/libvirt/images/lfs.img"
  IMAGE_CLONE_PATH="/var/lib/libvirt/images/lfs-clone.img"
  LIVE_VM_ISO_PATH="/var/lib/libvirt/images/alpine.iso"
elif [[ "$BUILD_MODE" == "vagrant_vbox" ]]; then
  echo "[INFO] BUILD_MODE is set to vagrant_vbox. Proceeding with Vagrant-specific setup..."
  IMAGE_PATH="/mnt/os_images/lfs.img"
  IMAGE_CLONE_PATH="/mnt/os_images/lfs-clone.img"
  LIVE_VM_ISO_PATH="/mnt/os_images/alpine.iso"
  [ ! -f  $LIVE_VM_ISO_PATH ] && (echo "[ERROR] Please put alpine.iso in $LIVE_VM_ISO_PATH" && exit 1)
fi

IMAGE_SIZE="30G"
VM_NAME="lfs-vm"
LIVE_VM_NAME="lfs-vm-live-debug"
VIRSH_POOL="default"
VIRSH_NETWORK="default"
LOOP_DEVICE=$(losetup -l | grep "$IMAGE_PATH" | awk '{print $1}')
CONF_TMP="/mnt/lfs/sources/conf_tmp"
GDT_HOSTNAME="0xHrtz"
LFS_ROOT="/mnt/lfs-root"
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin"

(mount | grep '/mnt/lfs/proc')    && sudo umount /mnt/lfs/proc
(mount | grep '/mnt/lfs/sys')     && sudo umount /mnt/lfs/sys
(mount | grep '/mnt/lfs/dev')     && sudo umount /mnt/lfs/dev
(mount | grep '/mnt/lfs/dev/pts') && sudo umount /mnt/lfs/dev/pts

echo "[INFO] Checking if VM_NAME or LIVE_VM_NAME exists..."
if virsh list --all | grep -q "$VM_NAME"; then
  echo "[INFO] VM $VM_NAME exists. Deleting..."
  sudo virsh destroy $VM_NAME || true
  sudo virsh undefine $VM_NAME || true
  echo "[INFO] VM $VM_NAME deleted successfully."
fi

if virsh list --all | grep -q "$LIVE_VM_NAME"; then
  echo "[INFO] VM $LIVE_VM_NAME exists. Deleting..."
  sudo virsh destroy $LIVE_VM_NAME || true
  sudo virsh undefine $LIVE_VM_NAME || true
  echo "[INFO] VM $LIVE_VM_NAME deleted successfully."
fi

echo "[INFO] Preparing LFS image at $IMAGE_PATH with size $IMAGE_SIZE..."
if [ -f "$IMAGE_PATH" ]; then
    sudo rm -f "$IMAGE_PATH"
    echo "[INFO] Removed existing image at $IMAGE_PATH"
fi

sudo qemu-img create -f raw $IMAGE_PATH 25G

[ -d $IMAGE_CLONE_PATH ] && sudo rm -f $IMAGE_CLONE_PATH 

echo "Unmounting existing partitions..."
[ -d /mnt/lfs-boot ] && sudo rm -rf /mnt/lfs-boot/*
[ -d /mnt/lfs-root ] && sudo rm -rf /mnt/lfs-root/* 

echo "[INFO] Unmounting all loop devices..."
LOOP_DEVICES=$(losetup -l | awk '{print $1}' | grep '/dev/loop')
for DEVICE in $LOOP_DEVICES; do
  sudo umount ${DEVICE}p1 || true
  sudo umount ${DEVICE}p2 || true
done

echo "[INFO] Cleaning up old loop devices..."
sudo losetup -D

echo "[INFO] Creating loop device..."
sudo losetup -fP $IMAGE_PATH
LOOP_DEVICE=$(losetup -l | grep "$IMAGE_PATH" | awk '{print $1}')

echo "[INFO] Creating partitions on $IMAGE_PATH..."
sudo parted -s $LOOP_DEVICE mklabel msdos
sudo parted -s $LOOP_DEVICE mkpart primary ext4 1MiB 512MiB
sudo parted -s $LOOP_DEVICE set 1 boot on
sudo parted -s $LOOP_DEVICE mkpart primary ext4 512MiB 100%

echo "[INFO] Formatting partitions..."
sudo mkfs.ext4 ${LOOP_DEVICE}p1
sudo mkfs.ext4 ${LOOP_DEVICE}p2

echo "[INFO] Mounting partitions..."
sudo mkdir -p /mnt/lfs-boot /mnt/lfs-root
sudo mount ${LOOP_DEVICE}p1 /mnt/lfs-boot
sudo mount ${LOOP_DEVICE}p2 /mnt/lfs-root

echo "[INFO] Copying content from /mnt/lfs/root to /mnt/lfs-root excluding boot..."
sudo rsync -a --stats --exclude='boot' --exclude='sources' /mnt/lfs/* /mnt/lfs-root/

echo "[INFO] Creating inittab, clock, fstab, ifconfig.ens3, resolv.conf, and hostname files..."
cat >  $CONF_TMP/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF

cat > $CONF_TMP/ifconfig.ens3 << "EOF"
ONBOOT=yes
IFACE=ens3
SERVICE=ipv4-static
IP=192.168.122.100
GATEWAY=192.168.122.1
PREFIX=24
BROADCAST=192.168.122.255
EOF

cat > $CONF_TMP/resolv.conf << "EOF"
# Begin /etc/resolv.conf

domain 0xHrtx.local
nameserver 8.8.8.8
nameserver 8.8.4.4

# End /etc/resolv.conf
EOF

cat > $CONF_TMP/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF

cat > $CONF_TMP/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point    type     options             dump  fsck
#                                                                order

/dev/vda1      /boot          ext4     defaults            1     1
/dev/vda2      /              ext4     defaults            1     1
proc           /proc          proc     nosuid,noexec,nodev 0     0
sysfs          /sys           sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts       devpts   gid=5,mode=620      0     0
tmpfs          /run           tmpfs    defaults            0     0
devtmpfs       /dev           devtmpfs mode=0755,nosuid    0     0
tmpfs          /dev/shm       tmpfs    nosuid,nodev        0     0
cgroup2        /sys/fs/cgroup cgroup2  nosuid,noexec,nodev 0     0

# End /etc/fstab
EOF

echo $GDT_HOSTNAME > $CONF_TMP/hostname

echo "[INFO] Copying configuration files to $LFS_ROOT..."
sudo /bin/cp $CONF_TMP/inittab           $LFS_ROOT/etc/inittab
sudo /bin/cp $CONF_TMP/clock             $LFS_ROOT/etc/sysconfig/clock
sudo /bin/cp $CONF_TMP/fstab             $LFS_ROOT/etc/fstab
sudo /bin/cp $CONF_TMP/ifconfig.ens3     $LFS_ROOT/etc/sysconfig/ifconfig.ens3
sudo /bin/cp $CONF_TMP/hostname          $LFS_ROOT/etc/hostname
sudo /bin/cp $CONF_TMP/profile           $LFS_ROOT/etc/profile
sudo /bin/cp $CONF_TMP/sysctl.conf       $LFS_ROOT/etc/sysctl.conf
sudo /bin/cp $CONF_TMP/hosts             $LFS_ROOT/etc/hosts
sudo /bin/cp $CONF_TMP/environment       $LFS_ROOT/etc/environment
sudo /bin/cp $CONF_TMP/bash_profile      $LFS_ROOT/root/.bash_profile

# Containers and CRI-O configuration
# [ -d $LFS_ROOT/etc/containers ]           || sudo mkdir -p $LFS_ROOT/etc/containers
# [ -d $LFS_ROOT/etc/crio ]                 || sudo mkdir -p $LFS_ROOT/etc/crio
# [ -d $LFS_ROOT/usr/lib/cni ]              || sudo mkdir -p $LFS_ROOT/usr/lib/cni
# [ -d $LFS_ROOT/etc/kubernetes ]           || sudo mkdir -p $LFS_ROOT/etc/kubernetes
# [ -d $LFS_ROOT/etc/kubernetes/certs ]     || sudo mkdir -p $LFS_ROOT/etc/kubernetes/certs
# [ -d $LFS_ROOT/etc/kubernetes/manifests ] || sudo mkdir -p $LFS_ROOT/etc/kubernetes/manifests
# [ -d $LFS_ROOT/usr/share/mkinitramfs ]    || sudo mkdir -p $LFS_ROOT/usr/share/mkinitramfs

# sudo /bin/cp $CONF_TMP/kube-apiserver.yaml          $LFS_ROOT/etc/kubernetes/manifests/kube-apiserver.yaml
# sudo /bin/cp $CONF_TMP/kube-controller-manager.yaml $LFS_ROOT/etc/kubernetes/manifests/kube-controller-manager.yaml
# sudo /bin/cp $CONF_TMP/kube-scheduler.yaml          $LFS_ROOT/etc/kubernetes/manifests/kube-scheduler.yaml
# sudo /bin/cp $CONF_TMP/etcd.yaml                    $LFS_ROOT/etc/kubernetes/manifests/etcd.yaml
# sudo /bin/cp $CONF_TMP/kubelet.conf                 $LFS_ROOT/etc/kubernetes/kubelet.conf
# sudo /bin/cp $CONF_TMP/kubelet-config.yaml          $LFS_ROOT/etc/kubernetes/kubelet-config.yaml

# sudo /bin/cp $CONF_TMP/kubelet.init                 $LFS_ROOT/etc/init.d/kubelet
# sudo /bin/cp $CONF_TMP/sshd.init                    $LFS_ROOT/etc/init.d/sshd
# sudo /bin/cp $CONF_TMP/crio.init                    $LFS_ROOT/etc/init.d/crio

# sudo /bin/cp $CONF_TMP/crio.conf                    $LFS_ROOT/etc/crio/crio.conf
# sudo /bin/cp $CONF_TMP/policy.json                  $LFS_ROOT/etc/containers/policy.json

# sudo /bin/cp $CONF_TMP/init.in                      $LFS_ROOT/usr/share/mkinitramfs/init.in
# sudo /bin/cp $CONF_TMP/mkinitramfs                  $LFS_ROOT/usr/sbin/mkinitramfs

# [ -L $LFS_ROOT/lib/libzstd.so.1 ] || sudo unlink $LFS_ROOT/lib/libzstd.so.1
# [ -f $LFS_ROOT/lib/libzstd.so.1 ] || sudo cp $LFS_ROOT/usr/local/lib/libzstd.so.1 $LFS_ROOT/lib/libzstd.so.1
# echo "[INFO] Check that $LFS_ROOT/lib/libzstd.so.1 esists"
# ls $LFS_ROOT/lib/libzstd.so.1 && echo "[INFO] $LFS_ROOT/lib/libzstd.so.1 exists"

# echo "[INFO] MD5 checksum of $LFS_ROOT/usr/sbin/mkinitramfs"
# md5sum $LFS_ROOT/usr/sbin/mkinitramfs

echo "[INFO] List init scripts in /etc/init.d..."
sudo ls -l $LFS_ROOT/etc/init.d/

# TODO
# echo "[INFO] Building service manager"
# old_pwd=$(pwd)
# cd /home/ubuntu/gdt/service-manager && sudo ./build.sh
# sudo cp service-manager $LFS_ROOT/usr/local/bin/service-manager
# sudo chmod +x $LFS_ROOT/usr/local/bin/service-manager
# echo "[INFO] Service manager built and copied to $LFS_ROOT/usr/local/bin/service-manager"
# cd $old_pwd

# TODO
# [ -f cni-plugins-linux-amd64-v1.3.0.tgz ] || curl -O -L --silent https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
# sudo tar -xzf cni-plugins-linux-amd64-v1.3.0.tgz -C $LFS_ROOT/usr/lib/cni/

sudo mkdir $LFS_ROOT/boot
echo "[INFO] Content copied successfully."

echo "[INFO] Installing GRUB on /mnt/lfs-boot..."
sudo grub-install --boot-directory=/mnt/lfs-boot/boot --root-directory=/mnt/lfs-boot --target=i386-pc $LOOP_DEVICE
echo "[INFO] GRUB installation completed successfully with specified root directory."
echo "[INFO] Partitions mounted successfully."

echo "[INFO] Copying content from /mnt/lfs/boot to /mnt/lfs-boot..."
sudo cp -a /mnt/lfs/boot/* /mnt/lfs-boot/
echo "[INFO] Content copied successfully."

sudo cat > $CONF_TMP/grub.cfg << "EOF"
set default=0
set timeout=10

menuentry "GNU/Linux, Linux 6.13.4-lfs-12.3" {
  set gfxmode=1280x1024
  set gfxpayload=keep

  linux /vmlinuz-6.13.4-lfs-12.3 root=/dev/vda2 ro console=tty1
  # initrd /initrd.img-6.13.4
  # nomodeset
}
EOF

[ -d /mnt/lfs-boot/boot/grub ] || sudo mkdir -p /mnt/lfs-boot/boot/grub
sudo cp $CONF_TMP/grub.cfg /mnt/lfs-boot/boot/grub/grub.cfg

# mkdir -p initramfs/{bin,sbin,etc,proc,sys,newroot}
# cat > initramfs/init << 'EOF'
# #!/bin/sh
# mount -t proc none /proc
# mount -t sysfs none /sys
# echo "Switching to real root..."
# exec switch_root /newroot /sbin/init
# EOF
# chmod +x initramfs/init

sudo chroot "$LFS_ROOT" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash \
    -c '
        # TODO
        # chmod +x /etc/init.d/crio
        # ls /etc/rc.d/rc3.d/S91crio || ln -s /etc/init.d/crio /etc/rc.d/rc3.d/S91crio
        # ls /etc/rc.d/rc5.d/S91crio || ln -s /etc/init.d/crio /etc/rc.d/rc5.d/S91crio
        # ls /etc/rc.d/rc0.d/K91crio || ln -s /etc/init.d/crio /etc/rc.d/rc0.d/K91crio
        # ls /etc/rc.d/rc6.d/K91crio || ln -s /etc/init.d/crio /etc/rc.d/rc6.d/K91crio

        # chmod +x /etc/init.d/kubelet
        # ls /etc/rc.d/rc3.d/S92kubelet || ln -s /etc/init.d/kubelet /etc/rc.d/rc3.d/S92kubelet
        # ls /etc/rc.d/rc5.d/S92kubelet || ln -s /etc/init.d/kubelet /etc/rc.d/rc5.d/S92kubelet
        # ls /etc/rc.d/rc0.d/K92kubelet || ln -s /etc/init.d/kubelet /etc/rc.d/rc0.d/K92kubelet
        # ls /etc/rc.d/rc6.d/K92kubelet || ln -s /etc/init.d/kubelet /etc/rc.d/rc6.d/K92kubelet

        # ls /lib/libzstd.so.1
  
        # /usr/sbin/mkinitramfs 6.13.4
    '

sudo umount /mnt/lfs-boot
sudo umount /mnt/lfs-root

echo "[INFO] Cloning the image to $IMAGE_CLONE_PATH..."
sudo cp -a $IMAGE_PATH $IMAGE_CLONE_PATH
echo "[INFO] Image cloned successfully to $IMAGE_CLONE_PATH."

echo "[INFO] Verifying no loop devices are mounted..."
MOUNTED_LOOP_DEVICES=$(losetup -l | awk '{print $1}' | grep '/dev/loop')
if [ -n "$MOUNTED_LOOP_DEVICES" ]; then
  echo "[INFO] Some loop devices are still mounted:"
  echo "$MOUNTED_LOOP_DEVICES"
  sudo umount $MOUNTED_LOOP_DEVICES
else
  echo "[INFO] No loop devices are mounted."
fi

echo "[INFO] Preparing LFS image completed successfully."
echo "[INFO] Info of image file:"
sudo ls -lh $IMAGE_PATH

#echo "[INFO] Copying CA certificates to LFS image completed successfully."
#sudo cp /etc/ssl/certs/ca-certificates.crt /mnt/lfs/etc/ssl/certs/

if [[ "$BUILD_MODE" == "host_kvm" ]]; then
  echo "[INFO] Creating a virtual machine to import LFS image..."
  sudo -i -u ubuntu virt-install \
    --name $VM_NAME \
    --memory 2048 \
    --disk path=$IMAGE_PATH,format=raw,bus=virtio,size=${IMAGE_SIZE%G} \
    --os-type linux \
    --os-variant generic \
    --network network=$VIRSH_NETWORK,model=virtio \
    --graphics vnc,listen=0.0.0.0 \
    --import \
    --noautoconsole \
    --video virtio

  echo "[INFO] Starting a virtual machine that boots from Alpine ISO..."
  sudo -i -u ubuntu virt-install \
    --name $LIVE_VM_NAME \
    --memory 512 \
    --disk path=$LIVE_VM_ISO_PATH,format=raw,bus=ide,device=cdrom \
    --disk path=$IMAGE_CLONE_PATH,format=raw,bus=virtio,size=${IMAGE_SIZE%G} \
    --os-type linux \
    --os-variant generic \
    --network network=$VIRSH_NETWORK,model=virtio \
    --graphics vnc,listen=0.0.0.0 \
    --import \
    --noautoconsole

  echo "[INFO] Virtual machine alpine-vm started successfully."
  echo "[INFO] Virtual machine $VM_NAME created successfully."
elif [[ "$BUILD_MODE" == "vagrant_box" ]]; then
  echo "[INFO] To Do..."
fi

