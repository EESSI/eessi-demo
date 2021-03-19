# Throwaway Slurm cluster with EESSI (using Magic Castle)

[Magic Castle](https://github.com/ComputeCanada/magic_castle)
was designed to recreate the Compute Canada user experience
in public clouds. Magic Castle uses the open-source software Terraform
and HashiCorp Language (HCL) to define the virtual machines, volumes, and
networks that are required to replicate a virtual HPC infrastructure. The
infrastructure definition is packaged as a Terraform module that users can
customize as they require. After deployment, the user is provided with a
complete HPC cluster software environment including a Slurm scheduler,
a Globus Endpoint, JupyterHub, LDAP, DNS, and a full set of research
software applications compiled by experts with EasyBuild. Magic Castle is
compatible with AWS, Microsoft Azure, Google Cloud, OpenStack, and OVH.

## Creating the cluster with the EESSI software stack 

Support for the [EESSI pilot repository](https://eessi.github.io/docs/pilot)
is baked into Magic Castle since version `9.2`. To begin, follow the general
[setup instructions for Magic Castle](https://github.com/ComputeCanada/magic_castle#setup).

The file `main.tf` contains Terraform modules and outputs. Modules are files
that define a set of resources that will be configured based on the inputs
provided in the module block. In the `main.tf` file, there is a module named
after your cloud provider, e.g.:
```
module "openstack"
```
This module corresponds
to the high-level infrastructure of your cluster. In your cloud provider module
set the value for the `software_stack` variable to `eessi` (the default is
`computecanada`), e.g.,:
```
module "openstack" {

  ...lot's of other settings...

  # Set stack
  software_stack = "eessi"
}
```
