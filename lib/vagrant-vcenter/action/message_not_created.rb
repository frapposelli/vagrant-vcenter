module VagrantPlugins
  module VCenter
    module Action
      # Prints out a message that the VM has not yet been created.
      class MessageNotCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t('vagrant_vcenter.power.vm_not_created'))
          @app.call(env)
        end
      end
    end
  end
end
