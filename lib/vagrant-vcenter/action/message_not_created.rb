module VagrantPlugins
  module VCenter
    module Action
      class MessageNotCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # FIXME: this error should be categorized
          env[:ui].info(I18n.t('vcenter.vm_not_created'))
          @app.call(env)
        end
      end
    end
  end
end
