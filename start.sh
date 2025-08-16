#!/bin/bash
ansible_cmd="ansible-playbook -i jenkins-lfs/inventories/hosts_prod.ini jenkins-lfs/playbooks/start.yml "

function create_vbox_vm_from_img() {
  OS_IMAGE_BASE_DIR=./os_images
  VM_NAME=GenericDistroToolkitVM01
  VBoxManage convertfromraw $OS_IMAGE_BASE_DIR/lfs.img $OS_IMAGE_BASE_DIR/lfs.vdi --format VDI
  VBoxManage createvm --name $VM_NAME --ostype "Linux_64" --register
  VBoxManage modifyvm "$VM_NAME" --memory 2048 --cpus 2 --vram 16 --ioapic on
  VBoxManage modifyvm "$VM_NAME" --nic1 nat
  VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
  VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" \
    --port 0 --device 0 --type hdd --medium $OS_IMAGE_BASE_DIR/lfs.vdi
  VBoxManage startvm "$VM_NAME" --type gui
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
  echo "15) Start AARCH64 VM on VirtualBox"
  echo "16) Exit"

  echo
  read -p "Enter your choice: " choice

  case $choice in
    0)
      echo "Building Jenkins Folders..."
      $ansible_cmd --tags amd64_folders,aarch64_folders
    ;;

    1)
      echo "Building AMD64 all Jenkins Jobs..."
      $ansible_cmd --tags amd64_jobs
      ;;

    2)
      echo "Building AMD64 cross_toolchain Jenkins Jobs..."
      $ansible_cmd --tags amd64_cross_toolchain
      ;;

    3)
      echo "Building AMD64 cross_compiling_temporary_tools Jenkins Jobs..."
      $ansible_cmd --tags amd64_cross_compiling_temporary_tools
      ;;

    4)
      echo "Building AMD64 chroot_and_building_additional_temporary_tools Jenkins Jobs..."
      $ansible_cmd --tags amd64_chroot_and_building_additional_temporary_tools
      ;;

    5)
      echo "Building AMD64 basic_system_software Jenkins Jobs..."
      $ansible_cmd --tags amd64_basic_system_software
      ;;

    6)
      echo "Building AMD64 system_configuration Jenkins Jobs..."
      $ansible_cmd --tags amd64_system_configuration
      ;;

    7)
      echo "Building AMD64 containers Jenkins Jobs..."
      $ansible_cmd --tags amd64_containers
      ;;

    8)
      echo "Building AARCH64 all Jenkins Jobs..."
      $ansible_cmd --tags aarch64_jobs
      ;;

    9)
      echo "Building AARCH64 cross_toolchain Jenkins Jobs..."
      $ansible_cmd --tags aarch64_cross_toolchain

      ;;

    10)
      echo "Building AARCH64 cross_compiling_temporary_tools Jenkins Jobs..."
      $ansible_cmd --tags aarch64_cross_compiling_temporary_tools
      ;;

    11)
      echo "Building AARCH64 chroot_and_building_additional_temporary_tools Jenkins Jobs..."
      $ansible_cmd --tags aarch64_chroot_and_building_additional_temporary_tools
      ;;

    12)
      echo "Building AARCH64 basic_system_software Jenkins Jobs..."
      $ansible_cmd --tags aarch64_basic_system_software
      ;;

    13)
      echo "Building AARCH64 system_configuration Jenkins Jobs..."
      $ansible_cmd --tags aarch64_system_configuration
      ;;

    14)
      echo "Building AARCH64 containers Jenkins Jobs..."
      $ansible_cmd --tags aarch64_containers
      ;;

    14)
      echo "Building AARCH64 containers Jenkins Jobs..."
      $ansible_cmd --tags aarch64_containers
      ;;

    15)
      echo "Starting AARCH64 VM on VirtualBox..."
      create_vbox_vm_from_img
      ;;

    16)
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

show_menu
