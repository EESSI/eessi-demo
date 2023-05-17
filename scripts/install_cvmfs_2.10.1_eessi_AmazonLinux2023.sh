#!/bin/bash

sudo yum install -y http://ecsft.cern.ch/dist/cvmfs/cvmfs-config/cvmfs-config-default-latest.noarch.rpm
sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-2.10.1/cvmfs-2.10.1-1.el9.$(uname -m).rpm
sudo yum install -y https://github.com/EESSI/filesystem-layer/releases/download/latest/cvmfs-config-eessi-latest.noarch.rpm

sudo bash -c "echo 'CVMFS_CLIENT_PROFILE="single"' > /etc/cvmfs/default.local"
sudo bash -c "echo 'CVMFS_QUOTA_LIMIT=10000' >> /etc/cvmfs/default.local"

sudo service autofs start
sudo cvmfs_config setup
