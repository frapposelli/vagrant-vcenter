module VagrantPlugins
  module VCenter
    module Action
      # Prints out a message that the VM will not be destroyed.
      class MessageWillNotDestroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(
            I18n.t(
              'vagrant_vcenter.power.will_not_destroy',
              name: env[:machine].name
            )
          )
          @app.call(env)
        end
      end
    end
  end
end
