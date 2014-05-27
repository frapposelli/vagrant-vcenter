module VagrantPlugins
  module VCenter
    module Action
      # Prints out a message that the VM is already running.
      class MessageAlreadyRunning
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t('vagrant_vcenter.power.vm_already_running'))
          @app.call(env)
        end
      end
    end
  end
end
