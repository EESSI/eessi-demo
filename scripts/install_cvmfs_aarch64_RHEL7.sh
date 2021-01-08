#!/bin/bash
sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-2.7.5/cvmfs-2.7.5-1.el7.aarch64.rpm \
                    https://ecsft.cern.ch/dist/cvmfs/cvmfs-2.7.5/cvmfs-fuse3-2.7.5-1.el7.aarch64.rpm \
                    https://ecsft.cern.ch/dist/cvmfs/cvmfs-config/cvmfs-config-none-1.0-2.noarch.rpm

sudo yum install -y https://github.com/EESSI/filesystem-layer/releases/download/v0.2.3/cvmfs-config-eessi-0.2.3-1.noarch.rpm

sudo bash -c "echo 'CVMFS_HTTP_PROXY=DIRECT' > /etc/cvmfs/default.local"
sudo bash -c "echo 'CVMFS_QUOTA_LIMIT=10000' >> /etc/cvmfs/default.local"

sudo cvmfs_config setup
