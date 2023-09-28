#!/bin/bash

# Gather information about the OS
. /etc/os-release

# Function to check if user has passwordless sudo rights for a particular command
check_command_sudo () {
  # I want word splitting on $1
  # shellcheck disable=SC2086
  if ! sudo -n $1 >& /dev/null ; then
    echo "Command '$1' cannot run under (passwordless) sudo,"
    echo "this script will most likely not succeed, exiting!"
    exit 1
  fi
}

echo "Attempting to install EESSI for operating system ($NAME : $VERSION)"
error_msg="Don't know how to handle operating system ($NAME : $VERSION)"
# Check whether we have a RHEL-like or Debian-like system
if [[ "${ID_LIKE}" =~ "rhel" ]] || [[ "${ID_LIKE}" =~ "fedora" ]] || [[ "${ID_LIKE}" =~ "centos" ]]
then
  # Make sure we have sudo rights for yum or none of this can work
  check_command_sudo "yum --help"
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
    AMAZON_LINUX_CVMFS_VERSION=2.11.0
    AMAZON_LINUX_CVMFS_PACKAGE_VERSION=${AMAZON_LINUX_CVMFS_VERSION}-1
    sudo yum install -y http://ecsft.cern.ch/dist/cvmfs/cvmfs-config/cvmfs-config-default-latest.noarch.rpm
    sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-${AMAZON_LINUX_CVMFS_VERSION}/cvmfs-libs-${AMAZON_LINUX_CVMFS_PACKAGE_VERSION}.el${rhel_version}."$(uname -m)".rpm
    sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-${AMAZON_LINUX_CVMFS_VERSION}/cvmfs-${AMAZON_LINUX_CVMFS_PACKAGE_VERSION}.el${rhel_version}."$(uname -m)".rpm
  else
    # Assume everything else is RHEL-like (install the yum repo and then cvmfs)
    sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
    sudo yum install -y cvmfs
  fi
  # Install the EESSI configuration
  sudo yum install -y https://github.com/EESSI/filesystem-layer/releases/download/latest/cvmfs-config-eessi-latest.noarch.rpm
elif [[ "${ID_LIKE}" =~ "debian" ]]
then
  check_command_sudo "apt-get --help"  # Make sure we have sudo rights for apt-get
  sudo apt-get install lsb-release wget
  wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb
  check_command_sudo "dpkg --help"  # Make sure we have sudo rights for dpkg
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
check_command_sudo "bash --help"  # Make sure we have sudo rights for bash
sudo bash -c "echo 'CVMFS_CLIENT_PROFILE=single' > /etc/cvmfs/default.local"
sudo bash -c "echo 'CVMFS_QUOTA_LIMIT=10000' >> /etc/cvmfs/default.local"

# Initialise cvmfs
check_command_sudo "cvmfs_config --help"  # Make sure we have sudo rights for cvmfs_config
sudo cvmfs_config setup
