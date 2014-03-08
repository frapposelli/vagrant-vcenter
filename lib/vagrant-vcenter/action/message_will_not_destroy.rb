module VagrantPlugins
  module VCenter
    module Action
      class MessageWillNotDestroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # FIXME: This error should be categorized
          env[:ui].info(
            I18n.t(
              'vagrant_vcenter.will_not_destroy',
              name: env[:machine].name
            )
          )
          @app.call(env)
        end
      end
    end
  end
end
