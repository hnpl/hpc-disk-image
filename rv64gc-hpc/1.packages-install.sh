#!/bin/bash

sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install build-essential git python3-pip gfortran cmake ninja-build git-lfs libomp-dev
# install numa library
sudo apt-get -y install numactl libnuma-dev libnuma1

pip install scons --user
pip install meson --user
