module VagrantPlugins
  module VCenter
    module Action
      # This class verifies if the VM has been created.
      class IsCreated
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::is_created')
        end

        def call(env)
          vm_id = env[:machine].id
          config = env[:machine].provider_config
          if vm_id
            if config.vcenter_cnx
              dc = config.vcenter_cnx.serviceInstance.find_datacenter(
                  config.datacenter_name) or abort 'datacenter not found'
              root_vm_folder = dc.vmFolder
              vm = root_vm_folder.findByUuid(env[:machine].id)
              if not vm
                @logger.warn('VM has not been created')
                env[:result] = false
              end
            end
            @logger.info("VM has been created and ID is: [#{vm_id}]")
            env[:result] = true
          else
            @logger.warn('VM has not been created')
            env[:result] = false
          end

          @app.call env
        end
      end
    end
  end
end
