#!/bin/bash

# Gather information about the OS
. /etc/os-release
echo "Attempting to install EESSI for operating system ($NAME : $VERSION)"
error_msg="Don't know how to handle operating system ($NAME : $VERSION)"
# Check whether we have a RHEL-like or Debian-like system
if [[ $ID_LIKE == *"rhel"* ]] || [[ $ID_LIKE == *"fedora"* ]] || [[ $ID_LIKE == *"centos"* ]]
then
  # No working yum repo for Amazon Linux so need to treat that special case
  if [[ $NAME == "Amazon Linux" ]]
  then
    if [[ $VERSION == "2" ]]
    then
      # Amazon Linux 2 maps to RHEL7 (roughly)
      rhel_version="7"
    elif [[ $VERSION == "2023" ]]
    then
      # This maps to RHEL9 (roughly)
      rhel_version="9"
    else
      echo "$error_msg"
      exit 1
    fi
    # Install CVMFS (without a yum repo for Amazon Linux), config file first, then CVMFS itself
    sudo yum install -y http://ecsft.cern.ch/dist/cvmfs/cvmfs-config/cvmfs-config-default-latest.noarch.rpm
    sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-2.10.1/cvmfs-2.10.1-1.el${rhel_version}.$(uname -m).rpm    
  else
    # Assume everything else is RHEL-like (install the yum repo and then cvmfs)
    sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
    sudo yum install -y cvmfs
  fi
  # Install the EESSI configuration
  sudo yum install -y https://github.com/EESSI/filesystem-layer/releases/download/latest/cvmfs-config-eessi-latest.noarch.rpm
elif [[ $ID_LIKE == *"debian"* ]]
then
  sudo apt-get install lsb-release wget
  wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb
  sudo dpkg -i cvmfs-release-latest_all.deb
  rm -f cvmfs-release-latest_all.deb
  sudo apt-get update
  sudo apt-get install -y cvmfs

  wget https://github.com/EESSI/filesystem-layer/releases/download/latest/cvmfs-config-eessi_latest_all.deb
  sudo dpkg -i cvmfs-config-eessi_latest_all.deb
  rm -f cvmfs-config-eessi_latest_all.deb
else
  echo "$error_msg"
  exit 1
fi

# Create a simple configuration
sudo bash -c "echo 'CVMFS_CLIENT_PROFILE="single"' > /etc/cvmfs/default.local"
sudo bash -c "echo 'CVMFS_QUOTA_LIMIT=10000' >> /etc/cvmfs/default.local"

# Initialise cvmfs
sudo cvmfs_config setup
