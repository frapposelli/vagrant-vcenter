module VagrantPlugins
  module VCenter
    module Action
      # This class powers on the VM that the Vagrant provider is managing.
      class PowerOn
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::power_on')
        end

        def call(env)
          cfg = env[:machine].provider_config

          vm = cfg.vmfolder.findByUuid(env[:machine].id) or
               fail Errors::VMNotFound,
                    :vm_name => env[:machine].name

          # Poweron VM
          env[:ui].info('Powering on VM...')
          vm.PowerOnVM_Task.wait_for_completion
          sleep(20) until env[:machine].communicate.ready?

          @app.call env
        end
      end
    end
  end
end
