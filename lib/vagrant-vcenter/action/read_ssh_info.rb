module VagrantPlugins
  module VCenter
    module Action
      # This class reads the IP info for the VM that the Vagrant provider is
      # managing using VMware Tools.
      class ReadSSHInfo
        # FIXME: More work needed here for vCenter logic (vApp, VM IPs, etc.)

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::read_ssh_info')
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call env
        end

        def read_ssh_info(env)
          return nil if env[:machine].id.nil?

          cfg = env[:machine].provider_config

          vm = cfg.vmfolder.findByUuid(env[:machine].id) or
               fail Errors::VMNotFound,
                    :vm_name => env[:machine].name

          address = vm.guest.ipAddress
          if not address or address == ''
            address = vm.guest_ip
          end

          if not address or address == ''
            # if we can't find it right away just return nil.  it will retry
            # till the vmware tools supplies the ip address back to vcenter
            @logger.debug('could not find booted guest ipaddress')
            return nil
          end

          @logger.debug("Setting nfs_machine_ip to #{address}")
          env[:nfs_machine_ip] = address

          { :host => address, :port => 22 }
        end
      end
    end
  end
end
