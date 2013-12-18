module VagrantPlugins
  module VCenter
    module Action
      class ForwardPorts
        include Util::CompileForwardedPorts

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcenter::action::forward_ports")
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
          ports = []

          cfg = @env[:machine].provider_config
          cnx = cfg.vCenter_cnx.driver
          vmName = @env[:machine].name
          vAppId = @env[:machine].get_vapp_id

          cfg.org = cnx.get_organization_by_name(cfg.org_name)
          cfg.vdc_network_id = cfg.org[:networks][cfg.vdc_network_name]

          @logger.debug("Getting VM info...")
          vm = cnx.get_vapp(vAppId)
          vmInfo = vm[:vms_hash][vmName.to_sym]


          @env[:forwarded_ports].each do |fp|
            message_attributes = {
              :guest_port => fp.guest_port,
              :host_port => fp.host_port
            }

            @env[:ui].info("Forwarding Ports: VM port #{fp.guest_port} -> vShield Edge port #{fp.host_port}")

            # Add the options to the ports array to send to the driver later
            ports << {
              :guestip   => fp.guest_ip,
              :nat_internal_port => fp.guest_port,
              :hostip    => fp.host_ip,
              :nat_external_port  => fp.host_port,
              :name      => fp.id,
              :nat_protocol  => fp.protocol.upcase,
              :vapp_scoped_local_id => vmInfo[:vapp_scoped_local_id]
            }
          end

          if !ports.empty?
            # We only need to forward ports if there are any to forward
            @logger.debug("Port object to be passed: #{ports.inspect}")
            @logger.debug("Current network id #{cfg.vdc_network_id}")

            ### Here we apply the nat_rules to the vApp we just built

            addports = cnx.add_vapp_port_forwarding_rules(
              vAppId,
              "Vagrant-vApp-Net",
              {
                :fence_mode => "natRouted",
                :parent_network => cfg.vdc_network_id,
                :nat_policy_type => "allowTraffic",
                :nat_rules => ports
              })

            wait = cnx.wait_task_completion(addports)

            if !wait[:errormsg].nil?
              raise Errors::ComposeVAppError, :message => wait[:errormsg]
            end

          end

        end
      end
    end
  end
end
