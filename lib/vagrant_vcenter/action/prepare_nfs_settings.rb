module VagrantPlugins
  module VCenter
    module Action
      # Prepare NFS Settings for data sharing
      class PrepareNFSSettings
        include Vagrant::Util::Retryable

        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::nfs')
        end

        def call(env)
          if env[:machine].state.id != :running
            raise Errors::MachineNotRunning,
                  :machine_name => env[:machine].name
          end

          host_ip = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address

          @logger.debug("Setting host_ip to #{host_ip}")

          env[:nfs_host_ip] = host_ip

          @app.call env
        end
      end
    end
  end
end
