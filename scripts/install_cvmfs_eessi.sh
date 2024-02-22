#!/bin/bash

# Dry run function
dry_run() {
    if [ "$DRY_RUN" = true ]; then
        echo "sudo $@"
    else
        eval "$@"
    fi
}

# Gather information about the OS
. /etc/os-release

# Perform actions based on the value of DRY_RUN
if [ "$EUID" -ne 0 ]; then
    echo
    echo "This script requires sudo privileges to actually install and configure the CVMFS packages."
    echo "If that is what you want, please run it with sudo."
    echo
    echo "Performing a dry run only..."
    echo "An attempt to install EESSI for operating system ($NAME : $VERSION) would require:"
    echo
    DRY_RUN=true
else
    echo "Attempting to install EESSI for operating system ($NAME : $VERSION):"
fi

error_msg="Don't know how to handle operating system ($NAME : $VERSION)"
# Check whether we have a RHEL-like or Debian-like system
if [[ "${ID_LIKE}" =~ "rhel" ]] || [[ "${ID_LIKE}" =~ "fedora" ]] || [[ "${ID_LIKE}" =~ "centos" ]]
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
    AMAZON_LINUX_CVMFS_VERSION=2.11.2
    AMAZON_LINUX_CVMFS_PACKAGE_VERSION=${AMAZON_LINUX_CVMFS_VERSION}-1
    dry_run "yum install -y http://ecsft.cern.ch/dist/cvmfs/cvmfs-config/cvmfs-config-default-latest.noarch.rpm"
    dry_run "yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-${AMAZON_LINUX_CVMFS_VERSION}/cvmfs-libs-${AMAZON_LINUX_CVMFS_PACKAGE_VERSION}.el${rhel_version}.$(uname -m).rpm"
    dry_run "yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-${AMAZON_LINUX_CVMFS_VERSION}/cvmfs-${AMAZON_LINUX_CVMFS_PACKAGE_VERSION}.el${rhel_version}.$(uname -m).rpm"
  else
    # Assume everything else is RHEL-like (install the yum repo and then cvmfs)
    dry_run "yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm"
    dry_run "yum install -y cvmfs"
  fi
  # Install the EESSI configuration (not strictly necessary as software.eessi.io ships in the default)
  dry_run "yum install -y https://github.com/EESSI/filesystem-layer/releases/download/latest/cvmfs-config-eessi-latest.noarch.rpm"
elif [[ "${ID_LIKE}" =~ "debian" ]] || [[ "${ID}" =~ "debian" ]]
then
  dry_run "apt-get install lsb-release wget"
  dry_run "wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest_all.deb"
  dry_run "dpkg -i cvmfs-release-latest_all.deb"
  dry_run "rm -f cvmfs-release-latest_all.deb"
  dry_run "apt-get update"
  dry_run "apt-get install -y cvmfs"

  # Install the EESSI configuration (not strictly necessary as software.eessi.io ships in the default)
  dry_run "wget https://github.com/EESSI/filesystem-layer/releases/download/latest/cvmfs-config-eessi_latest_all.deb"
  dry_run "dpkg -i cvmfs-config-eessi_latest_all.deb"
  dry_run "rm -f cvmfs-config-eessi_latest_all.deb"
else
  echo "$error_msg"
  exit 1
fi

# Create a simple configuration
dry_run "bash -c \"echo 'CVMFS_CLIENT_PROFILE=single' > /etc/cvmfs/default.local\""
dry_run "bash -c \"echo 'CVMFS_QUOTA_LIMIT=10000' >> /etc/cvmfs/default.local\""

# Initialise cvmfs
dry_run "cvmfs_config setup"
