require "awesome_print"

module VagrantPlugins
  module VCenter
    module Action
      class ReadSSHInfo

        # FIXME: More work needed here for vCenter logic (vApp, VM IPs, etc.)

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcenter::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call env
        end


        def read_ssh_info(env)
          return nil if env[:machine].id.nil?

          config = env[:machine].provider_config
          dc = config.vcenter_cnx.serviceInstance.find_datacenter(config.datacenter_name) or abort "datacenter not found"
          root_vm_folder = dc.vmFolder
          vm = root_vm_folder.findByUuid(env[:machine].id)

          @logger.debug("IP Address: #{vm.guest.ipAddress}")

          return {
            # FIXME: these shouldn't be self
              :host => vm.guest.ipAddress,
              :port => 22
          }
        end
      end
    end
  end
end
