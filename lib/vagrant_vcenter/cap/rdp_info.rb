module VagrantPlugins
  module VCenter
    module Cap
      # RDP operations for Windows support
      module RDP
        # Reads the RDP forwarded port that currently exists on the machine
        # itself. This raises an exception if the machine isn't running.
        # @return [Hash<Integer, Integer>] Host => Guest port mappings.
        def self.rdp_info(machine)
          env = machine.action('read_rdp_info')
          env[:machine_ssh_info]
        end
      end
    end
  end
end
