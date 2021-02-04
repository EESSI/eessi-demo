# Throwaway Slurm cluster with EESSI (using Cluster-in-the-Cloud)

![Cluster-in-the-Cloud](https://cluster-in-the-cloud.readthedocs.io/en/latest/_static/logo.png)

Documentation on creating a throwaway Slurm cluster in the cloud (AWS)
using [Cluster-in-the-Cloud](https://cluster-in-the-cloud.readthedocs.io) (CitC),
with access to the [EESSI pilot repository](https://eessi.github.io/docs/pilot).

## Step 1: Creating the cluster

### Step 1.1: Install the AWS CLI tool, and configure it

On your local workstation or laptop:

* Install AWS CLI tool, see https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html;

* Create AWS access key via https://console.aws.amazon.com/iam/home#/security_credentials;

* Configure the AWS CLI tool to access your AWS account:
  ```
  aws configure
  ```

### Step 1.2: Use the CitC 1-click installer

*(see [https://cluster-in-the-cloud.readthedocs.io/en/latest/aws-infrastructure.html#click-installer](https://cluster-in-the-cloud.readthedocs.io/en/latest/aws-infrastructure.html#click-installer))*

```shell
git clone https://github.com/clusterinthecloud/installer.git
cd installer
```

```shell
./install-citc.sh aws  # use --region to specify specific AWS region to use
```

This will take a while to set up the login node of the cluster in AWS,
followed by creating a standard node image for `x86_64` compute nodes.

### Step 1.3 Finalize the cluster

*(see https://cluster-in-the-cloud.readthedocs.io/en/latest/finalise.html)*

Log in to the login node of your cluster, using the IP printed by the 1-click installer.

Note:

* use `citc` as username (management account);
* use the SSH private key that was created by the CitC 1-click installer;
* maybe add `-o IdentitiesOnly=yes` to avoid `Too many authentication failures` if you have many different SSH keys;

```shell
AWS_IP=...  # enter public AWS IP of the login node here
ssh -o IdentitiesOnly=yes -i citc-terraform-example/citc-key citc@$AWS_IP
```

Once you are logged in, run the `finish` command.

You may have to wait for a while and retry to get it to complete correctly,
since the initial node image may still not be fully created. You can check progress on that
via `/root/ansible-pull.log` on the login node.

### Step 1.4 Specify node types and counts

Create a `limits.yaml` file on the login node that specifies the node types and how many of each can be created.

Here's an example with 12 nodes in total, of 4 different types:

```yaml
# 3x Intel Haswell (4 cores, 7.5GB)
c4.xlarge: 3
# 3x Intel Cascade Lake/Skylake (4 cores, 8GB)
c5.xlarge: 3
# 3x AMD Rome (4 cores, 8GB)
c5a.xlarge: 3
# 3x Arm Gravition 2 (4 cores, 8GB)
c6g.xlarge: 3
```

After creating this file, run the `finish` command again (with the `citc` user).

Then check with `sinfo` whether Slurm is active:

```shell
$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
compute*     up   infinite      0    n/a
```

And check the list of compute node with the `list_nodes` command:
```shell
$ list_nodes
NODELIST                        STATE       REASON                        CPUS S:C:T   MEMORY    AVAIL_FEATURES                          GRES                NODE_ADDR      TIMESTAMP
example-c4-xlarge-0001          idle~       none                          4    1:2:2   6708      shape=c4.xlarge,ad=None,arch=x86_64     (null)              example-c4-x    Unknown
example-c4-xlarge-0002          idle~       none                          4    1:2:2   6708      shape=c4.xlarge,ad=None,arch=x86_64     (null)              example-c4-x    Unknown
example-c4-xlarge-0003          idle~       none                          4    1:2:2   6708      shape=c4.xlarge,ad=None,arch=x86_64     (null)              example-c4-x    Unknown
example-c4-xlarge-0004          idle~       none                          4    1:2:2   6708      shape=c4.xlarge,ad=None,arch=x86_64     (null)              example-c4-x    Unknown
example-c5a-xlarge-0001         idle~       none                          4    1:2:2   7199      shape=c5a.xlarge,ad=None,arch=x86_64    (null)              example-c5a-    Unknown
example-c5a-xlarge-0002         idle~       none                          4    1:2:2   7199      shape=c5a.xlarge,ad=None,arch=x86_64    (null)              example-c5a-    Unknown
example-c5a-xlarge-0003         idle~       none                          4    1:2:2   7199      shape=c5a.xlarge,ad=None,arch=x86_64    (null)              example-c5a-    Unknown
example-c5a-xlarge-0004         idle~       none                          4    1:2:2   7199      shape=c5a.xlarge,ad=None,arch=x86_64    (null)              example-c5a-    Unknown
example-c5-xlarge-0001          idle~       none                          4    1:2:2   7199      shape=c5.xlarge,ad=None,arch=x86_64     (null)              example-c5-x    Unknown
example-c5-xlarge-0002          idle~       none                          4    1:2:2   7199      shape=c5.xlarge,ad=None,arch=x86_64     (null)              example-c5-x    Unknown
example-c5-xlarge-0003          idle~       none                          4    1:2:2   7199      shape=c5.xlarge,ad=None,arch=x86_64     (null)              example-c5-x    Unknown
example-c5-xlarge-0004          idle~       none                          4    1:2:2   7199      shape=c5.xlarge,ad=None,arch=x86_64     (null)              example-c5-x    Unknown
example-c6g-xlarge-0001         idle~       none                          4    1:4:1   7199      shape=c6g.xlarge,ad=None,arch=arm64     (null)              example-c6g-    Unknown
example-c6g-xlarge-0002         idle~       none                          4    1:4:1   7199      shape=c6g.xlarge,ad=None,arch=arm64     (null)              example-c6g-    Unknown
example-c6g-xlarge-0003         idle~       none                          4    1:4:1   7199      shape=c6g.xlarge,ad=None,arch=arm64     (null)              example-c6g-    Unknown
example-c6g-xlarge-0004         idle~       none                          4    1:4:1   7199      shape=c6g.xlarge,ad=None,arch=arm64     (null)              example-c6g-    Unknown
```

### Step 1.5 Create a user account

Create a personal account, next to the `citc` administrative account.

You can leverage the SSH public keys registered in your GitHub account.

* Replace `USERNAME` with the desired (usually lowercase) name for the personal user account;
* Replace `YOUR_GITHUB_ACCOUNT` with your GitHub user name;
* Use your actual first/last name (or somethin funny you make up, go wild!).

```shell
sudo /usr/local/sbin/add_user_ldap USERNAME YourFirstName YourLastName https://github.com/YOUR_GITHUB_ACCOUNT.keys
```

Then log out of the `citc` management account, and try logging in with your personal account:

```shell
ssh USERNAME@$AWS_IP
```

### Step 1.6 Submit your first job

Try starting an interactive job on a specific node type:

```shell
srun --constraint=shape=c6g.xlarge --pty /bin/bash
```

Keep in mind that it will take a couple of minutes before your job starts: compute nodes are only actually
booted when jobs are submitted, and they are automatically shut down when there are no more jobs (after 10 min., by default).

## Step 2: Leverage EESSI

To access the EESSI pilot repository, you need to install CernVM-FS and do some minimal local configuration.

### Step 2.1 Mount EESSI repository on login node

To access EESSI on the login nodes, run the following commands using the `citc` account:

```shell
# install CernVM-FS 
sudo dnf install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
sudo dnf install -y cvmfs
# install EESSi CernVM-FS configuration repository
sudo dnf install -y https://github.com/EESSI/filesystem-layer/releases/download/v0.2.3/cvmfs-config-eessi-0.2.3-1.noarch.rpm
# add local CernVM-FS configuration file (2.5GB cache)
sudo bash -c "echo 'CVMFS_HTTP_PROXY=DIRECT' > /etc/cvmfs/default.local"
sudo bash -c "echo 'CVMFS_QUOTA_LIMIT=2500' >> /etc/cvmfs/default.local"
# complete CernVM-FS setup
sudo cvmfs_config setup
```

### Step 2.2 Create node images that include EESSI

To access the EESSI pilot repository on the compute nodes, you need to create a new node image
that includes CernVM-FS and the local configuration file.

* Add the following commands to the `compute_image_extra.sh` script on the login node (using the `citc` management account):
  ```shell
  if [[ $(arch) == "aarch64" ]]; then
      # no package available for CernVM-FS for CentOS 8 and aarch64 systems, so building from source...
      sudo dnf install -y cmake fuse-devel fuse3-devel fuse3-libs gcc-c++ libcap-devel libuuid-devel make openssl-devel patch python2 python3-devel unzip valgrind zlib-devel
      CVMFS_VERSION=2.8.0
      curl -OL https://github.com/cvmfs/cvmfs/archive/cvmfs-${CVMFS_VERSION}.tar.gz
      tar xfz cvmfs-${CVMFS_VERSION}.tar.gz
      cd cvmfs*${CVMFS_VERSION}
      mkdir build
      cd build
      cmake ..
      make -j $(nproc)
      sudo make install
  
      sudo dnf install -y attr autofs
      sudo dnf install -y fuse
  
      # fuse3 must be around for building, but not at runtime (for CentOS 8);
      # causes failure to mount CernVM-FS filesystems (FUSE3 version is too old?)
      sudo dnf remove -y fuse3-libs fuse3-devel
  else
      sudo dnf install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
      sudo dnf install -y cvmfs
  fi
  
  # update sudo, see https://access.redhat.com/errata/RHSA-2021:0218
  sudo yum update sudo
  
  # install CernVM-FS configuration for EESSI
  sudo dnf install -y https://github.com/EESSI/filesystem-layer/releases/download/v0.2.3/cvmfs-config-eessi-0.2.3-1.noarch.rpm
  
  # configure CernVM-FS (no proxy, 10GB quota for CernVM-FS cache)
  sudo bash -c "echo 'CVMFS_HTTP_PROXY=DIRECT' > /etc/cvmfs/default.local"
  sudo bash -c "echo 'CVMFS_QUOTA_LIMIT=10000' >> /etc/cvmfs/default.local"
  sudo cvmfs_config setup
  ```

* Create a new node image for the `x86_64` node types using the following command:
  ```
  sudo /usr/local/bin/run-packer
  ```
  This will take a couple of minutes to complete. Once done, `x86_64` compute nodes that are started
  will have access to EESSI.

* For the Arm64 Graviton2 nodes, we need to create a specific node image, using:
  ```
  sudo /usr/local/bin/run-packer aarch64
  ```
  This will take a bit longer (since CernVM-FS has to be compiled from source for CentOS 8 and `aarch64`).

## Step 3: Science!

Now go save the world with your throwaway Slurm cluster, with scientific software provided by
[EESSI](https://www.eessi-hpc.org)!
