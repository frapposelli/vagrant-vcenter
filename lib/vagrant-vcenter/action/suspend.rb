module VagrantPlugins
  module VCenter
    module Action
      # This class suspends the VM when it's powered on.
      class Suspend
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::suspend')
        end

        def call(env)
          cfg = env[:machine].provider_config

          vm = cfg.vmfolder.findByUuid(env[:machine].id) or
               fail Errors::VMNotFound,
                    :vm_name => env[:machine].name

          # Poweroff VM
          env[:ui].info('Suspending VM...')
          vm.SuspendVM_Task.wait_for_completion

          @app.call env
        end
      end
    end
  end
end
