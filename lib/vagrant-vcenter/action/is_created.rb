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
          if vm_id

            # VM is in the vagrant registry, now we need to check if it's
            # actually in vcenter

            # FIXME: this part needs some cleanup
            config = env[:machine].provider_config

            # FIXME: Raise a correct exception
            dc = config.vcenter_cnx.serviceInstance.find_datacenter(
                 config.datacenter_name) or abort 'datacenter not found'

            root_vm_folder = dc.vmFolder

            vm = root_vm_folder.findByUuid(env[:machine].id)

            unless vm
              @logger.info('VM is in the vagrant registry but not in vcenter')
              # Clear the ID
              env[:machine].id = nil
              env[:result] = false
            end

            # VM is in the registry AND in vcenter
            @logger.info("VM has been created and ID is: [#{vm_id}]")
            env[:result] = true

          else
            # VM is not in the registry
            @logger.warn('VM has not been created')
            env[:result] = false
          end

          @app.call env
        end
      end
    end
  end
end
