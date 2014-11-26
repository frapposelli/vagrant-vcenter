module VagrantPlugins
  module VCenter
    module Action
      # This class destroy the VM created by the Vagrant provider.
      class Destroy
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::destroy')
        end

        def call(env)
          cfg = env[:machine].provider_config

          vm = cfg.vmfolder.findByUuid(env[:machine].id) or
               fail Errors::VMNotFound,
                    :vm_name => env[:machine].name

          # Poweron VM
          env[:ui].info('Destroying VM...')
          vm.Destroy_Task.wait_for_completion
          env[:machine].id = nil
        end
      end
    end
  end
end
