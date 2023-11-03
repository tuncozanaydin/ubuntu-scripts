#!/bin/bash

SCRIPT_NAME="setup.sh"
PERSONAL_WEBPAGE="http://www.tuncaydin.com"
DISTRO="ubuntu2204"
ARCH="x86_64"
KEYRING="1.1"
CUDA_VERSION="cuda12.2"
CUDNN_VERSION="8.9.5.*"


tasks() {
    printf "0. [Setup spinning HD] Create ext4 partition using gparted.\n \
    Get UUID of the spinning drive using sudo blkid.\n \
    Create the mount point: mkdir /storage && sudo chown -R tunc:tunc /storage\n \
    sudo nano /etc/fstab and add UUID=<uuid>	/storage	ext4	defaults	0	2\n" 
    
    printf "0. Install Ubuntu 22.04 through GUI installer on the host machine.\
Minimal installation, no updates, no 3rd party drivers.\n"

    printf "0. [Enable sudo w/o password] sudo EDITOR=nano visudo, then edit \
the corresponding line as follows: %%sudo   ALL=(ALL:ALL) NOPASSWD: ALL\n"

    printf "0. [Enable remote ssh] sudo apt-get install openssh-server\n \
Then enable remote login from GUI settings.\n"

    printf "0. [Get ${SCRIPT_NAME}] git clone https://github.com/tuncozanaydin/ubuntu-scripts.git \
&& cd ubuntu-scripts && chmod +x ${SCRIPT_NAME} \n"

    printf "1. [Install required tools] ./${SCRIPT_NAME} required\n"

    printf "2. [Install NVIDIA drivers and reboot] ./${SCRIPT_NAME} nvidia \
&& reboot\n"

    printf "3. [Check NVIDIA drivers] ./${SCRIPT_NAME} check-nvidia\n"
    
    printf "4. [Install CUDA and reboot] ./${SCRIPT_NAME} cuda && reboot\n"

    printf "5. [Install CUDNN and reboot] ./${SCRIPT_NAME} cudnn && reboot\n"

    printf "6. [Generate ssh key and add it to github] ./${SCRIPT_NAME} sshkey\n"

    printf "7. [OpenImageIO] Download OpenImageIO wheel from oiio-pack\n \
    Create storage location for libs: mkdir /storage/lib\n \
    Copy to worker, e.g.: rsync -avz --progress ~/Downloads/oiiopack.whl tunc@<ip>:/storage/lib/\n"
}

# Install basic tools
# sudo with no passwd
# update, upgrade and install wget, git, ssh, etc.
install_nvidia() {
    sudo apt-get autoremove nvidia* --purge
    sudo apt-get -y install nvidia-driver-525
}

check_nvidia() {
    nvidia-smi
}

install_required() {
    sudo apt-get update -y
    sudo apt-get upgrade -y 
    sudo apt-get install -y --no-install-recommends build-essential \
    ca-certificates software-properties-common openssh-server git gparted \
    python3-venv
    echo 'export PYTHONPYCACHEPREFIX=~/.pycache' >> ~/.profile
}

# Function to install NVIDIA drivers
install_nvidia() {
    sudo apt-get update
    sudo ubuntu-drivers autoinstall
    sudo reboot
}

# Function to install CUDA
install_cuda() {
    sudo apt-get install linux-headers-$(uname -r)
    sudo apt-key del 7fa2af80
    wget https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${ARCH}/cuda-keyring_${KEYRING}-1_all.deb
    sudo dpkg -i cuda-keyring_{$KEYRING}-1_all.deb
    sudo apt-get update
    sudo apt-get install -y cuda-toolkit
    sudo apt-get install -y nvidia-gds
    echo 'export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}' >> ~/.profile
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.profile
}

# Function to install cuDNN
install_cudnn() {
    sudo apt-get install zlib1g
    sudo apt-get install libcudnn8=${CUDNN_VERSION}-1+${CUDA_VERSION}
    sudo apt-get install libcudnn8-dev=${CUDNN_VERSION}-1+${CUDA_VERSION}
    sudo apt-get install libcudnn8-samples=${CUDNN_VERSION}-1+${CUDA_VERSION}
}

gen_sshkey() {
    mkdir work
    ssh-keygen -t ed25519 -C "tuncozanaydin@gmail.com"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    cat ~/.ssh/id_ed25519.pub
    printf "copy and paste the above to github"
}

# Parsing arguments
for arg in "$@"
do
    case $arg in
        tasks)
            tasks
            ;;
        nvidia)
            install_nvidia
            ;;
        check-nvidia)
            check_nvidia
            ;;
        sshkey)
            gen_sshkey
            ;;
        required)
            install_required
            ;;
        cuda)
            install_cuda
            ;;
        cudnn)
            install_cudnn
            ;;
        *)
            echo "Invalid argument: $arg"
            ;;
    esac
done
