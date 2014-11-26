module VagrantPlugins
  module VCenter
    module Action
      # This class powers off the VM that the Vagrant provider is managing.
      class PowerOff
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::poweroff')
        end

        def call(env)
          cfg = env[:machine].provider_config

          vm = cfg.vmfolder.findByUuid(env[:machine].id) or
               fail Errors::VMNotFound,
                    :vm_name => env[:machine].name

          # Poweroff VM
          env[:ui].info('Powering off VM...')
          vm.PowerOffVM_Task.wait_for_completion

          @app.call env
        end
      end
    end
  end
end
