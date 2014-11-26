module VagrantPlugins
  module VCenter
    module Action
      # This class resumes the VM when it's suspended.
      class Resume
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::resume')
        end

        def call(env)
          cfg = env[:machine].provider_config

          vm = cfg.vmfolder.findByUuid(env[:machine].id) or
               fail Errors::VMNotFound,
                    :vm_name => env[:machine].name

          # Poweroff VM
          env[:ui].info('Powering on VM...')
          vm.PowerOnVM_Task.wait_for_completion

          @app.call env
        end
      end
    end
  end
end
