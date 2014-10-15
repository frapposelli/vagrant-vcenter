[Vagrant](http://www.vagrantup.com) provider for VMware vCenter®
=============

[Version 0.3.2](../../releases/tag/v0.3.2) has been released!
-------------

Please note that this software is still Alpha/Beta quality and is not recommended for production usage.

We have a wide array of boxes available at [Vagrant Cloud](https://vagrantcloud.com/gosddc) you can use them directly or you can roll your own as you please, make sure to install VMware tools in it.

This plugin supports the universal [```vmware_ovf``` box format](https://github.com/gosddc/packer-post-processor-vagrant-vmware-ovf/wiki/vmware_ovf-Box-Format), that is 100% portable between [vagrant-vcloud](https://github.com/frapposelli/vagrant-vcloud), [vagrant-vcenter](https://github.com/gosddc/vagrant-vcenter) and [vagrant-vcloudair](https://github.com/gosddc/vagrant-vcloudair), no more double boxes!.

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
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'vcenter'

nodes = []

[*1..5].each do |n|
  nodes << { hostname: "centos#{n}",
             box: 'gosddc/centos65-x64',
             ip: "10.250.21.#{n}",
             mem: 1024 * n,
             cpu: n }
end

[*1..5].each do |n|
  nodes << { hostname: "precise#{n}",
             box: 'gosddc/precise32',
             ip: "10.250.22.#{n}",
             mem: 1024 * n,
             cpu: n }
end

Vagrant.configure('2') do |config|

  # Go through nodes and configure each of them.
  nodes.each do |node|

    config.vm.provider :vcenter do |vcenter|
      vcenter.hostname = 'my.vcenter.hostname'
      vcenter.username = 'myUsername'
      vcenter.password = 'myPassword'
      vcenter.folder_name = 'myFolderName'
      vcenter.datacenter_name = 'MyDatacenterName'
      vcenter.computer_name = 'MyHostOrCluster'
      vcenter.datastore_name = 'MyDatastore'
      vcenter.network_name = 'myNetworkName'
      vcenter.linked_clones = true
    end

    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = node[:box]
      node_config.vm.hostname = node[:hostname]

      # Let's configure the network for the VM, only the ip changes and is
      # coming from the nodes array
      node_config.vm.network :public_network,
                             ip: node[:ip],
                             netmask: '255.255.0.0',
                             gateway: '10.250.254.254',
                             dns_server_list: ['8.8.4.4', '8.8.8.8'],
                             dns_suffix_list: ['ad.lab.gosddc.com']
      
      # Let's override some provider settings for specific VMs
      node_config.vm.provider :vcenter do |override|
        # Override number of cpu and memory based on what's in the nodes array
        override.num_cpu = node[:cpu]
        override.memory = node[:mem]
        case node[:hostname]
        # Override the folder name based on the hostname of the VM
        when /centos/
          override.folder_name = 'Vagrant/centos'
        when /precise/
          override.folder_name = 'Vagrant/ubuntu/precise'
          override.enable_vm_customization = false
        end
      end
      node_config.nfs.functional = false
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
