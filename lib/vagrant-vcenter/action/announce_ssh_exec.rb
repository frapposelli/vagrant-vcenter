module VagrantPlugins
  module VCenter
    module Action
      class AnnounceSSHExec < Vagrant::Action::Builtin::SSHExec
        def initialize(app, env)
          @app = app
        end

        def call(env)
          sshInfo = env[:machine].ssh_info
          env[:ui].success("External IP for #{env[:machine].name}: #{sshInfo[:host]}")
          super
        end
      end
    end
  end
end
