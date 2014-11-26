
module VagrantPlugins
  module VCenter
    module Action
      # This class verifies if the VM has been created.
      class IsCreated
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::is_created')
        end

        def call(env)
          vm_id = env[:machine].id

          if vm_id
            @logger.info("VM has been created and ID is: [#{vm_id}]")
            env[:result] = true
          else
            # VM is not in the registry
            @logger.warn('VM has not been created')
            env[:result] = false
          end

          @app.call env
        end
      end
    end
  end
end
