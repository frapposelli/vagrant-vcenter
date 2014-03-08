module VagrantPlugins
  module VCenter
    module Action
      class ForwardPorts
        include Util::CompileForwardedPorts

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::forward_ports')
        end

        #--------------------------------------------------------------
        # Execution
        #--------------------------------------------------------------
        def call(env)
          @env = env

          # Get the ports we're forwarding
          env[:forwarded_ports] ||= compile_forwarded_ports(env[:machine].config)

          forward_ports

          @app.call(env)
        end

        def forward_ports
          # FIXME: This isn't used yet for sure, it was vagrant-vcloud code
          #        (tsugliani)
        end
      end
    end
  end
end
