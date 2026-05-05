#!/bin/bash
# Note: The cvmfs package server has a browseable mirror under
# https://cvmrepo.s3.cern.ch/cvmrepo -> https://cvmrepo.web.cern.ch/cvmrepo

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
  dry_run "yum install -y https://cvmrepo.s3.cern.ch/cvmrepo/yum/cvmfs-release-latest.noarch.rpm"
  dry_run "yum install -y cvmfs"
elif [[ "${ID_LIKE}" =~ "debian" ]] || [[ "${ID}" =~ "debian" ]]
then
  dry_run "apt-get update"
  dry_run "apt-get install -y lsb-release wget"
  dry_run "wget https://cvmrepo.s3.cern.ch/cvmrepo/apt/cvmfs-release-latest_all.deb"
  dry_run "dpkg -i cvmfs-release-latest_all.deb"
  dry_run "rm -f cvmfs-release-latest_all.deb"
  dry_run "apt-get update"
  dry_run "apt-get install -y cvmfs"
else
  echo "$error_msg"
  exit 1
fi

# Create a simple configuration
dry_run "bash -c \"echo 'CVMFS_CLIENT_PROFILE=single' > /etc/cvmfs/default.local\""
dry_run "bash -c \"echo 'CVMFS_QUOTA_LIMIT=10000' >> /etc/cvmfs/default.local\""
# Use a CDN to control the load on the public mirrors of EESSI
dry_run "bash -c \"echo 'CVMFS_USE_CDN=yes' >> /etc/cvmfs/default.local\""

# Initialise cvmfs
dry_run "cvmfs_config setup"
