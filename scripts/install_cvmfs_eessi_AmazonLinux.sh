#!/bin/bash

# Make sure we are on Amazon Linux 2 or 2023
if grep "Amazon Linux release 2" /etc/system-release > /dev/null ; then
    # We have a valid relase, now which one
    if grep "Amazon Linux release 2023" /etc/system-release > /dev/null ; then
        # This maps to RHEL9 (roughly)
        rhel_version="9"
    else
        # Amazon Linux 2 maps to RHEL7 (roughly)
        rhel_version="7"
    fi
else
    echo
    echo "You do not seem to be using AmazonLinux 2 or 2023, the rest of this script won't work!" >&2
    echo
    exit 1
fi

# Install CVMFS (no working yum repo for Amazon Linux)
sudo yum install -y http://ecsft.cern.ch/dist/cvmfs/cvmfs-config/cvmfs-config-default-latest.noarch.rpm
sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-2.10.1/cvmfs-2.10.1-1.el${rhel_version}.$(uname -m).rpm
sudo yum install -y https://github.com/EESSI/filesystem-layer/releases/download/latest/cvmfs-config-eessi-latest.noarch.rpm

# Create a simple configuration
sudo bash -c "echo 'CVMFS_CLIENT_PROFILE="single"' > /etc/cvmfs/default.local"
sudo bash -c "echo 'CVMFS_QUOTA_LIMIT=10000' >> /etc/cvmfs/default.local"

# Initialise cvmfs
sudo cvmfs_config setup
