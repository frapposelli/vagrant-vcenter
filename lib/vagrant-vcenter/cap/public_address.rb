module VagrantPlugins
  module VCenter
    module Cap
      module PublicAddress
        def self.public_address(machine)
          # Initial try for vagrant share feature.
          # It seems ssh_info[:port] is given automatically.
          # I think this feature was built planning that the port forwarding
          # and networking was done on the vagrant machine, which isn't the
          # case in vagrant-vcloud

          ssh_info = machine.ssh_info
          ssh_info[:host]
        end
      end
    end
  end
end
