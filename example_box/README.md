# vagrant-vcenter box specifications [WIP]

*Note that vagrant-vcenter currently supports only single VM vApp boxes*

BOX package should contain:

- `metadata.json` -- Vagrant metadata file
- `<boxname>.ovf` -- OVF descriptor of the vApp.
- `<boxname>.mf` -- OVF manifest file containing file hashes.
- `<boxname>-disk-<#>.vmdk` -- Associated VMDK files.
- `Vagrantfile`-- vagrant-vcenter default Vagrantfile

A [task is open](https://github.com/frapposelli/vagrant-vcenter/issues/12) for creating a veewee plugin to facilitate Box creation