# Packer scripts for building HPC disk images

##### Table of Contents
- [Status](#status)
- [Downloading Packer](#downloading-packer)
- [Dependencies](#dependencies)
- [Building the rv64gc Disk Image](#building-the-rv64gc-disk-image)
- [Building the arm64 Disk Image](#building-the-arm64-disk-image)
- [Building the arm64sve Disk Image](#building-the-arm64sve-disk-image)
- [Building the x86_64 Disk Image](#building-the-x86_64-disk-image)

## Status

|                     | rv64gc | arm64 | arm64sve | x86_64 |
| ------------------- | ------ | ----- | -------- | ------ |
| stream              |     ✔ |    ✔ |       ✔ |     ✔ |
| gups                |     ✔ |    ✔ |       ✔ |     ✔ |
| spatter             |     ✔ |    ✔ |       ✔ |     ✔ |
| npb                 |   ✔ \*|  ✔\* |     ✔\* |   ✔\* |
| MemoryLatencyTest   |     ✔ |    ✔ |       ✔ |     ✔ |
| permutating-scatter |     ✔ |    ✔ |       ✔ |     ✔ |
| permutating-gather  |     ✔ |    ✔ |       ✔ |     ✔ |

\*Compiling is.D.x resulted in compilation error.

## Downloading Packer

See [https://developer.hashicorp.com/packer/downloads](https://developer.hashicorp.com/packer/downloads).

## Dependencies

```sh
apt-get install cloud-image-utils qemu-efi-aarch64 qemu-system qemu-utils
```

## Building the rv64gc Disk Image

### Downloading the Pre-installed RISC-V Disk Image

We choose to work with this disk image because this disk image is known to work with QEMU.

See [https://ubuntu.com/download/risc-v](https://ubuntu.com/download/risc-v).

```sh
wget https://cdimage.ubuntu.com/releases/22.04.2/release/ubuntu-22.04.2-preinstalled-server-riscv64+unmatched.img.xz
xz -dk ubuntu-22.04.2-preinstalled-server-riscv64+unmatched.img.xz
mv ubuntu-22.04.2-preinstalled-server-riscv64+unmatched.img rv64gc-hpc-2204.img
qemu-img resize rv64gc-hpc-2204.img +20G
```

### Launching a QEMU Instance

```sh
qemu-system-riscv64 -machine virt -nographic \
     -m 16384 -smp 8 \
     -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
     -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
     -device virtio-net-device,netdev=eth0 \
     -netdev user,id=eth0,hostfwd=tcp::5555-:22 \
     -drive file=rv64gc-hpc-2204.img,format=raw,if=virtio
```

### Changing the Default Password

Upon the first boot, when you try to login to the `ubuntu` account, the OS will ask you to change the password.
The default password is `ubuntu`.
The new password should be `automato`, which is specified in `rv64gc-hpc.json`.

To login to the guest machine,

```sh
ssh -p 5555 ubuntu@localhost
```

### Running the Packer Script

While the QEMU Instance is running,

```sh
./packer build rv64gc-hpc.json
```

## Building the arm64 Disk Image

### Downloading the arm64 Cloud Disk Image

See [https://cloud-images.ubuntu.com/](https://cloud-images.ubuntu.com/).

```sh
wget https://cloud-images.ubuntu.com/releases/22.04/release-20230616/ubuntu-22.04-server-cloudimg-arm64.img
qemu-img convert ubuntu-22.04-server-cloudimg-arm64.img -O raw ./arm64-hpc-2204.img
qemu-img resize -f raw arm64-hpc-2204.img +20G
```

### Setting up an SSH key pair

The default key path is `~/.ssh/id_rsa` might overwrite a current key.
You can change the key path, and make a corresponding change in
`arm64-hpc.json`.

```sh
ssh-keygen -C "ubuntu@localhost"
ssh-add ~/.ssh/id_rsa
```

### Making a Cloud Init Config Image

Typically a cloud image will use `cloud-init` to initialize a cloud instance.
In this case, we will use `cloud-init` to set up an SSH key so that we can login
to the guest QEMU instance.
This is necessary as the downloaded cloud image does not contain any user.
Setting up a cloud init config allows us to create a user on the first boot.

We will create a file called `cloud.txt` to store the cloud init configuration.
Typically the configuration looks like,

```
#cloud-config
users:
  - name: ubuntu
    lock_passwd: false
    groups: sudo
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    ssh-authorized-keys:
      - ssh-rsa AAAAJLKFJEWOIJRNJF... <- insert the public key here (e.g., the content of ~/.ssh/id_rsa.pub)
```

Then, we create a cloud init image that we can input to qemu later,

```sh
cloud-localds --disk-format qcow2 cloud.img cloud.txt
```

Note that this image is of the qcow2 format.

### Launching a QEMU Instance

```sh
dd if=/dev/zero of=flash0.img bs=1M count=64
dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=flash0.img conv=notrunc
dd if=/dev/zero of=flash1.img bs=1M count=64
qemu-system-aarch64 -m 16384 -smp 8 -cpu cortex-a57 -M virt \
    -nographic -pflash flash0.img -pflash flash1.img \
    -drive if=none,file=arm64-hpc-2204.img,id=hd0 -device virtio-blk-device,drive=hd0 \
    -drive if=none,id=cloud,file=cloud.img -device virtio-blk-device,drive=cloud \
    -netdev user,id=user0 -device virtio-net-device,netdev=eth0 \
    -netdev user,id=eth0,hostfwd=tcp::5555-:22
```

### Running the Packer Script

While the QEMU Instance is running,

```sh
./packer build arm64-hpc.json
```

## Building the arm64sve Disk Image
This is similar to building the arm disk image, except for the packer json file
is now `arm64sve-hpc.json`.

## Building the x86_64 Disk Image

### Downloading the x86_64 Cloud Disk Image

See [https://cloud-images.ubuntu.com/](https://cloud-images.ubuntu.com/).

```sh
wget https://cloud-images.ubuntu.com/releases/22.04/release-20230616/ubuntu-22.04-server-cloudimg-amd64.img
qemu-img convert ubuntu-22.04-server-cloudimg-amd64.img -O raw ./x86_64-hpc-2204.img
qemu-img resize -f raw ./x86_64-hpc-2204.img +20G
```

### Setting up an SSH key pair

The default key path is `~/.ssh/id_rsa` might overwrite a current key.
You can change the key path, and make a corresponding change in
`x86_64-hpc.json`.

```sh
ssh-keygen -C "ubuntu@localhost"
ssh-add ~/.ssh/id_rsa
```

### Making a Cloud Init Config Image

Typically a cloud image will use `cloud-init` to initialize a cloud instance.
In this case, we will use `cloud-init` to set up an SSH key so that we can login
to the guest QEMU instance.
This is necessary as the downloaded cloud image does not contain any user.
Setting up a cloud init config allows us to create a user on the first boot.

We will create a file called `cloud.txt` to store the cloud init configuration.
Typically the configuration looks like,

```
#cloud-config
users:
  - name: ubuntu
    lock_passwd: false
    groups: sudo
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    ssh-authorized-keys:
      - ssh-rsa AAAAJLKFJEWOIJRNJF... <- insert the public key here (e.g., the content of ~/.ssh/id_rsa.pub)
```

Then, we create a cloud init image that we can input to qemu later,

```sh
cloud-localds --disk-format qcow2 cloud.img cloud.txt
```

Note that this image is of the qcow2 format.

### Launching a QEMU Instance

```sh
qemu-system-x86_64 \
     -nographic -m 16384 -smp 8 \
     -device virtio-net-pci,netdev=eth0 -netdev user,id=eth0,hostfwd=tcp::5555-:22 \
     -drive file=x86_64-hpc-2204.img,format=raw \
     -drive if=none,id=cloud,file=cloud.img -device virtio-blk-pci,drive=cloud
```

### Running the Packer Script

While the QEMU Instance is running,

```sh
./packer build x86_64-hpc.json
```
