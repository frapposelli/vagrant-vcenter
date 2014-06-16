[Vagrant](http://www.vagrantup.com) provider for VMware vCenter®
=============

[Version 0.2.0](../../releases/tag/v0.2.0) has been released!
-------------

Please note that this software is still Alpha/Beta quality and is not recommended for production usage.

Right now a [Precise32](http://vagrant.gosddc.com/boxes/precise32-vcenter.box) is available for use, or you can roll your own as you please, make sure to install VMware tools in it.

Changes in [version 0.2.0](../../releases/tag/v0.2.0) include:

New Features

- Add option to set the actual vm name
- Set some options in the vm via linux prep
- Static networking
- Hostname
- Add option to set vmnetwork name and backing
- Vagrant now uses builtin ```SyncedFolders``` helper to synchronize folders

Fixes

- Fix the read_ssh_info if the vm doesn't have a network yet at first try the later ssh's wont forever fail

Many thanks to @BarnacleBob for submitting PR #4 with all these new features!

Changes in [version 0.1.1](../../releases/tag/v0.1.1) include:

- Support for ```vagrant share``` [Fixes [#2](../../issues/2)]
- Support for [Vagrant Cloud](http://vagrantcloud.com) boxes [Fixes [#1](../../issues/1)]

Install
-------------

Latest version can be easily installed by running the following command:

```vagrant plugin install vagrant-vcenter```

Vagrant will download all the required gems during the installation process.

If you already have the plugin installed you can use:

```vagrant plugin upgrade vagrant-vcenter```

To perform an upgrade to the latest version.

After the install has completed a ```vagrant up --provider=vcenter``` will trigger the newly installed provider.

Configuration
-------------

Here's a sample Multi-VM Vagrantfile:

```ruby
precise32_box_url = 'http://vagrant.gosddc.com/boxes/precise32-vcenter.box'

nodes = [
  { hostname: 'web-vm',
    box: 'precise32',
    box_url: precise32_box_url },
  { hostname: 'ssh-vm',
    box: 'precise32',
    box_url: precise32_box_url },
  { hostname: 'sql-vm',
    box: 'precise32',
    box_url: precise32_box_url },
  { hostname: 'lb-vm',
    box: 'precise32',
    box_url: precise32_box_url }
]

Vagrant.configure('2') do |config|

  config.vm.provider :vcenter do |vcenter|
    vcenter.hostname = 'my.vcenter.hostname'
    vcenter.username = 'myUsername'
    vcenter.password = 'myPassword'
    vcenter.folder_name = 'myFolderName'
    vcenter.datacenter_name = 'MyDatacenterName'
    vcenter.computer_name = 'MyHostOrCluster'
    vcenter.datastore_name = 'MyDatastore'
    vcenter.template_folder_name = 'My/Template/Folder/Path'
    vcenter.network_name = 'myNetworkName'
    # If you want to use linked clones, set this to true
    vcenter.linked_clones = true
  end

  # Go through nodes and configure each of them.j
  nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = node[:box]
      node_config.vm.hostname = node[:hostname]
      node_config.vm.box_url = node[:box_url]
    #   node_config.vm.provision :puppet do |puppet|
    #     puppet.manifests_path = 'puppet/manifests'
    #     puppet.manifest_file = 'site.pp'
    #     puppet.module_path = 'puppet/modules'
    #     puppet.options = "--verbose --debug"
    #   end
    end
  end
end
```

Contribute
-------------

What is still missing:

- TEST SUITES! (working on that).
- Speed, the code is definitely not optimized.
- Thorough testing.
- Error checking is absymal.
- Some spaghetti code here and there.
- Bugs, bugs and BUGS!.

If you're a developer and want to lend us a hand, head over to our ```develop``` branch and send us PRs!
