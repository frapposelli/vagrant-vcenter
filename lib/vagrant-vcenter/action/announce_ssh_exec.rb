module VagrantPlugins
  module VCenter
    module Action
      # Extends the Builtin SSHExec and announces the external IP.
      class AnnounceSSHExec < Vagrant::Action::Builtin::SSHExec
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].state.id != :running
            fail Errors::MachineNotRunning,
                 :machine_name => env[:machine].name
          end

          ssh_info = env[:machine].ssh_info
          env[:ui].success(
            "External IP for #{env[:machine].name}: #{ssh_info[:host]}"
          )

          super
        end
      end
    end
  end
end
