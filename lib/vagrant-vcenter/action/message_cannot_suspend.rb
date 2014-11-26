module VagrantPlugins
  module VCenter
    module Action
      # Prints out a message that the VM is already halted and cannot be
      # suspended
      class MessageCannotSuspend
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(
            I18n.t('vagrant_vcenter.power.vm_halted_cannot_suspend')
          )
          @app.call(env)
        end
      end
    end
  end
end
