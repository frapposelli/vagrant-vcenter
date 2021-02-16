module VagrantPlugins
  module VCenter
    module Action
      # This Class read the power state of the VM that Vagrant is managing.
      class ReadState
        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::read_state')
        end

        def call(env)
          env[:machine_state_id] = read_state(env)
          @app.call env
        end

        def read_state(env)
          if env[:machine].id.nil?
            @logger.info('VM is not created yet')
            return :not_created
          end

          cfg = env[:machine].provider_config

          vm = cfg.vmfolder.findByUuid(env[:machine].id) or
            raise Errors::VMNotFound,
                  :vm_name => env[:machine].name

          # @logger.debug("Current power state: #{vm.runtime.powerState}")
          vm_name = env[:machine].name

          if vm.nil?
            # If the VM has been cloned/moved, the findByUuid call returns nil
            @logger.info("VM [#{vm_name}] state is unknown")
            :unknown
          elsif vm.runtime.powerState == 'poweredOff'
            @logger.info("VM [#{vm_name}] is stopped")
            :stopped
          elsif vm.runtime.powerState == 'poweredOn'
            @logger.info("VM [#{vm_name}] is running")
            :running
          elsif vm.runtime.powerState == 'suspended'
            @logger.info("VM [#{vm_name}] is suspended")
            :suspended
          end
        end
      end
    end
  end
end
