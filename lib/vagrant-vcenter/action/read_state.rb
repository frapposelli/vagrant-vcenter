require 'log4r'

module VagrantPlugins
  module VCenter
    module Action
      # This Class read the power state of the VM that Vagrant is managing.
      class ReadState
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::read_state')
        end

        def call(env)
          env[:machine_state_id] = read_state(env)
          @app.call env
        end

        def read_state(env)
          # FIXME: this part needs some cleanup
          config = env[:machine].provider_config

          # FIXME: Raise a correct exception
          dc = config.vcenter_cnx.serviceInstance.find_datacenter(
               config.datacenter_name) or abort 'datacenter not found'

          root_vm_folder = dc.vmFolder

          vm = root_vm_folder.findByUuid(env[:machine].id)

          #@logger.debug("Current power state: #{vm.runtime.powerState}")
          vm_name = env[:machine].name

          if env[:machine].id.nil?
            @logger.info("VM [#{vm_name}] is not created yet")
            return :not_created
          end

          if vm.runtime.powerState == 'poweredOff'
            @logger.info("VM [#{vm_name}] is stopped")
            return :stopped
          elsif vm.runtime.powerState == 'poweredOn'
            @logger.info("VM [#{vm_name}] is running")
            return :running
          elsif vm.runtime.powerState == 'suspended'
            @logger.info("VM [#{vm_name}] is suspended")
            return :suspended
          end
        end
      end
    end
  end
end
