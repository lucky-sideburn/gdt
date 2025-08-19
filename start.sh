#!/bin/bash

function create_qemu_vm_from_img() {
  OS_IMAGE_BASE_DIR=./os_images
  VM_NAME=GenericDistroToolkitVM01
  #[ -f $OS_IMAGE_BASE_DIR/lfs.qcow2 ] && rm -f $OS_IMAGE_BASE_DIR/lfs.qcow2
  # echo "Creating QEMU VM from image: $OS_IMAGE_BASE_DIR/lfs.img"
  qemu-img convert -f raw -O qcow2 $OS_IMAGE_BASE_DIR/lfs.img $OS_IMAGE_BASE_DIR/lfs.qcow2
  qemu-img convert -f raw -O qcow2 $OS_IMAGE_BASE_DIR/lfs-clone.img $OS_IMAGE_BASE_DIR/lfs-clone.qcow2

  echo "Starting Alpine Linux that mounts the LFS image for debugging..."
  qemu-system-aarch64 \
      -M virt \
      -cpu host \
      -accel hvf \
      -smp 2 \
      -m 2048 \
      -drive file=$OS_IMAGE_BASE_DIR/alpine.iso,if=virtio,media=cdrom \
      -drive file=$OS_IMAGE_BASE_DIR/lfs-clone.qcow2,if=virtio,format=qcow2 \
      -drive file=$OS_IMAGE_BASE_DIR/lfs.qcow2,if=virtio,format=qcow2 \
      -netdev user,id=net0,hostfwd=tcp::2222-:22 \
      -device virtio-net-device,netdev=net0 \
      -device virtio-gpu-pci \
      -device usb-ehci \
      -device usb-kbd \
      -display cocoa \
      -bios /opt/homebrew/Cellar/qemu/10.0.3/share/qemu/edk2-aarch64-code.fd \
      -serial mon:stdio \
      -boot d

  # echo "Starting the AARCH64 VM with the LFS image..."
  qemu-system-aarch64 \
      -M virt \
      -cpu host \
      -accel hvf \
      -smp 2 \
      -m 2048 \
      -drive file=$OS_IMAGE_BASE_DIR/lfs.qcow2,if=virtio,format=qcow2 \
      -netdev user,id=net0,hostfwd=tcp::2222-:22 \
      -device virtio-net-device,netdev=net0 \
      -device virtio-gpu-pci \
      -device usb-ehci \
      -device usb-kbd \
      -display cocoa \
      -bios /opt/homebrew/Cellar/qemu/10.0.3/share/qemu/edk2-aarch64-code.fd \
      -serial mon:stdio \
      -boot c
}

ansible_cmd() {
  if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: 'ansible-playbook' command not found. Please install Ansible before running this script."
    exit 1
  fi

  if [ ! -f jenkins-lfs/inventories/hosts_prod.ini ]; then
    echo "Error: Inventory file 'hosts_prod.ini' not found in 'jenkins-lfs/inventories/'."
    echo "Please create it from jenkins-lfs/inventories/hosts.ini. It contains secrets like Jenkins credentials."
    exit 1
  else
    echo "Inventory file found. Proceeding..."
    echo
  fi

  ansible-playbook -i jenkins-lfs/inventories/hosts_prod.ini jenkins-lfs/playbooks/start.yml "$@"
}

function show_menu() {
  echo "Select an option:"
  echo "0)  Create Jenkins Folders" 
  echo "1)  Build AMD64 all Jenkins Jobs"
  echo "2)  Build AMD64 cross_toolchain Jenkins Jobs"
  echo "3)  Build AMD64 cross_compiling_temporary_tools Jenkins Jobs"
  echo "4)  Build AMD64 chroot_and_building_additional_temporary_tools Jenkins Jobs"
  echo "5)  Build AMD64 basic_system_software Jenkins Jobs"
  echo "6)  Build AMD64 system_configuration Jenkins Jobs"
  echo "7)  Build AMD64 containers Jenkins Jobs"
  echo "8)  Build AARCH64 all Jenkins Jobs"
  echo "9)  Build AARCH64 cross_toolchain Jenkins Jobs"
  echo "10) Build AARCH64 cross_compiling_temporary_tools Jenkins Jobs"
  echo "11) Build AARCH64 chroot_and_building_additional_temporary_tools Jenkins Jobs"
  echo "12) Build AARCH64 basic_system_software Jenkins Jobs"
  echo "13) Build AARCH64 system_configuration Jenkins Jobs"
  echo "14) Build AARCH64 containers Jenkins Jobs"
  echo "15) Start AARCH64 VM on QEMU"
  echo "16) Provision an AARCH64 build node using Vagrant"
  echo "17) Provision an AMD64 build node directly with Ansible"
  echo "18) Exit"

  echo
  read -p "Enter your choice: " choice

  case $choice in
    0)
      echo "Building Jenkins Folders..."
      ansible_cmd --tags amd64_folders,aarch64_folders
    ;;

    1)
      echo "Building AMD64 all Jenkins Jobs..."
      ansible_cmd --tags amd64_jobs
      ;;

    2)
      echo "Building AMD64 cross_toolchain Jenkins Jobs..."
      ansible_cmd --tags amd64_cross_toolchain
      ;;

    3)
      echo "Building AMD64 cross_compiling_temporary_tools Jenkins Jobs..."
      ansible_cmd --tags amd64_cross_compiling_temporary_tools
      ;;

    4)
      echo "Building AMD64 chroot_and_building_additional_temporary_tools Jenkins Jobs..."
      ansible_cmd --tags amd64_chroot_and_building_additional_temporary_tools
      ;;

    5)
      echo "Building AMD64 basic_system_software Jenkins Jobs..."
      ansible_cmd --tags amd64_basic_system_software
      ;;

    6)
      echo "Building AMD64 system_configuration Jenkins Jobs..."
      ansible_cmd --tags amd64_system_configuration
      ;;

    7)
      echo "Building AMD64 containers Jenkins Jobs..."
      ansible_cmd --tags amd64_containers
      ;;

    8)
      echo "Building AARCH64 all Jenkins Jobs..."
      ansible_cmd_cmd --tags aarch64_jobs
      ;;

    9)
      echo "Building AARCH64 cross_toolchain Jenkins Jobs..."
      ansible_cmd --tags aarch64_cross_toolchain

      ;;

    10)
      echo "Building AARCH64 cross_compiling_temporary_tools Jenkins Jobs..."
      ansible_cmd --tags aarch64_cross_compiling_temporary_tools
      ;;

    11)
      echo "Building AARCH64 chroot_and_building_additional_temporary_tools Jenkins Jobs..."
      ansible_cmd --tags aarch64_chroot_and_building_additional_temporary_tools
      ;;

    12)
      echo "Building AARCH64 basic_system_software Jenkins Jobs..."
      ansible_cmd --tags aarch64_basic_system_software
      ;;

    13)
      echo "Building AARCH64 system_configuration Jenkins Jobs..."
      ansible_cmd --tags aarch64_system_configuration
      ;;

    14)
      echo "Building AARCH64 containers Jenkins Jobs..."
      ansible_cmd --tags aarch64_containers
      ;;

    14)
      echo "Building AARCH64 containers Jenkins Jobs..."
      ansible_cmd --tags aarch64_containers
      ;;

    15)
      echo "Preparing AARCH64 VM on QEMU (Vagrant AARCH64 Build Node)..."
      create_qemu_vm_from_img
      ;;

    16)
      echo "Provisioning an AARCH64 build node using Vagrant..."
      [ -f Vagrantfile ] || (echo "Error. Vagrantfile not found" ; exit 1)
      if ! vagrant status | grep -q "running"; then
        echo "Vagrant VM is not running. Starting it with 'vagrant up'..."
        vagrant up
      else
        echo "Vagrant VM is already running."
      fi
      vagrant provision
      ;;

    17)
      echo "Provisioning an AMD64 build node directly with Ansible..."
      ansible-playbook -i jenkins-lfs/inventories/hosts_prod.ini jenkins-lfs/playbooks/amd64_lfs.yml
      ;;

    18)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      show_menu
      ;;
  esac
}

echo
echo "========================================="
echo " Welcome to the Generic Distro Toolkit! "
echo "========================================="
echo

show_menu
