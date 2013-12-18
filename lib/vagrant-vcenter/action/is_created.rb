module VagrantPlugins
  module VCenter
    module Action
      class IsCreated
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcenter::action::is_created")
        end

        def call(env)
         
          vmId = env[:machine].id
            if vmId
              @logger.info("VM has been created and ID is: [#{vmId}]")
              env[:result] = true
           else
              @logger.warn("VM has not been created")
              env[:result] = false
           end

          @app.call env
        end
      end
    end
  end
end
