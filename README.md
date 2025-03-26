# EESSI Demo Examples
Small examples for various scientific software applications included in the [EESSI software repository](https://www.eessi.io/docs/).

See the `scripts` directory for useful scripts that can help you quickly install EESSI on Ubuntu or RHEL-based systems.


## GPU examples
For showcasing the GPU options and instalation in EESSI 
there is `gpu/` folder.
We wanted to perserve "working" example of the scripts, which anyone can use right away.
This is the reason some parts of the demo are duplicated.

install.sh script installs EESSI and then tries to provide correct CUDA package/module/libraries. 

run-demo-<PACKAGE>.sh scripts runs demo package.
It is written in such a way:
- check if all the modules are present (if not it builds them).
- first tests CPU version of the software 
- runs it 3 times (so we can see if there is overhead in module loading the first time).
- after that it runs GPU enabled version of the software.
- runs it again 3 times - module load overhead/cache over CVMFS

Support stuff:

`*.eb` modules - They were not present in latest EB 4.x. so we just copied them. 
They will be removed, once we are sure the demo works without local .eb files.

`gpu/scripts/*` is copy of `/cvmfs/software.eessi.io/versions/${EESSI_VERSION}/scripts/` 
with updated `gpu_support/nvidia/link_nvidia_host_libraries.sh` which fixes duplicate libraries found - PR already present,
and with updated `gpu_support/nvidia/install_cuda_host_injections.sh` that produces Lmod which is needed on one special case.
This will be removed once it is either updated in upstream, or will not be needed in future EESSI.


There are some scripts that are duplicated for various reasons.
It could be that upstream script was not yet updated (merged PR) and it wouldn't work without the change.
Some files were added for comfort of the users.
Some are duplicated so we have some control over the versions.


## License

The software in this repository is distributed under the terms of the
[GNU General Public License v2.0](https://opensource.org/licenses/GPL-2.0).

See [LICENSE](https://github.com/EESSI/eessi-demo/blob/main/LICENSE) for more information.

SPDX-License-Identifier: GPL-2.0-only
