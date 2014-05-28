require 'etc'
require 'log4r'
require 'rbvmomi'
require 'rbvmomi/utils/deploy'
require 'rbvmomi/utils/admission_control'
require 'yaml'

module VagrantPlugins
  module VCenter
    module Action
      # This Class inspect the vCenter inventory for templates and uploads it
      # if needed.
      class InventoryCheck
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new(
                    'vagrant_vcenter::action::inventory_check')
        end

        def call(env)
          vcenter_check_inventory(env)
          @app.call env
        end

        def vcenter_upload_box(env)
          config = env[:machine].provider_config

          box_dir = env[:machine].box.directory.to_s

          if env[:machine].box.name.to_s.include? '/'
            box_file = env[:machine].box.name.rpartition('/').last.to_s
            box_name = env[:machine].box.name.to_s.gsub(/\//, '-')
          else
            box_file = env[:machine].box.name.to_s
            box_name = box_file
          end

          box_ovf = "file://#{box_dir}/#{box_file}.ovf"

          # Still relying on ruby-progressbar because report_progress basically
          # sucks.

          @logger.debug("OVF File: #{box_ovf}")

          env[:ui].info("Adding [#{box_name}]")

          # FIXME: Raise a correct exception
          dc = config.vcenter_cnx.serviceInstance.find_datacenter(
               config.datacenter_name) or fail 'datacenter not found'

          root_vm_folder = dc.vmFolder
          vm_folder = root_vm_folder
          if config.template_folder_name.nil?
            vm_folder = root_vm_folder.traverse(config.template_folder_name,
                                                RbVmomi::VIM::Folder)
          end
          template_folder = root_vm_folder.traverse!(
                            config.template_folder_name,
                            RbVmomi::VIM::Folder)

          template_name = box_name

          # FIXME: Raise a correct exception
          datastore = dc.find_datastore(
                      config.datastore_name) or fail 'datastore not found'
          # FIXME: Raise a correct exception
          computer = dc.find_compute_resource(
                      config.computer_name) or fail 'Host not found'

          network = computer.network.find { |x| x.name == config.network_name }

          deployer = CachedOvfDeployer.new(
            config.vcenter_cnx,
            network,
            computer,
            template_folder,
            vm_folder,
            datastore
          )

          deployer_opts = {
            :run_without_interruptions => true,
            :simple_vm_name => true
          }

          deployer.upload_ovf_as_template(
                                          box_ovf,
                                          template_name,
                                          deployer_opts)
          # FIXME: Progressbar??
        end

        def vcenter_check_inventory(env)
          # Will check each mandatory config value against the vcenter
          # Instance and will setup the global environment config values
          config = env[:machine].provider_config
          # FIXME: Raise a correct exception
          dc = config.vcenter_cnx.serviceInstance.find_datacenter(
               config.datacenter_name) or fail 'datacenter not found'

          if env[:machine].box.name.to_s.include? '/'
            box_file = env[:machine].box.name.rpartition('/').last.to_s
            box_name = env[:machine].box.name.to_s.gsub(/\//, '-')
          else
            box_file = env[:machine].box.name.to_s
            box_name = box_file
          end

          if config.template_folder_name.nil?
            box_to_search = box_name
          else
            box_to_search = config.template_folder_name +
                            '/' + box_name
          end

          @logger.debug("This is the box we're looking for: #{box_to_search}")

          config.template_id = dc.find_vm(box_to_search)

          if config.template_id.nil?
            env[:ui].warn("Template [#{box_name}] " +
                          'does not exist!')

            user_input = env[:ui].ask(
              "Would you like to upload the [#{box_name}]" +
              " box?\nChoice (yes/no): "
            )

            if user_input.downcase == 'yes' || user_input.downcase == 'y'
              env[:ui].info("Uploading [#{box_name}]...")
              vcenter_upload_box(env)
            else
              env[:ui].error('Template not uploaded, exiting...')

              # FIXME: wrong error message
              fail VagrantPlugins::VCenter::Errors::VCenterError,
                   :message => 'Catalog not available, exiting...'

            end
          else
            @logger.debug("Template found at #{box_to_search}")
          end
        end
      end
    end
  end
end
