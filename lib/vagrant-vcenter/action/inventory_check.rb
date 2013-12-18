require "etc"
require "log4r"
require 'rbvmomi'
require 'rbvmomi/utils/deploy'
require 'rbvmomi/utils/admission_control'
require 'yaml'

module VagrantPlugins
  module VCenter
    module Action
      class InventoryCheck

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcenter::action::inventory_check")
        end

        def call(env)
          vcenter_check_inventory(env)
            
          @app.call env
        end

        def vcenter_upload_box(env)

          config = env[:machine].provider_config

          # config.vcenter_cnx

          #@logger.debug("Box... #{env[:machine].box.inspect}")

          boxDir = env[:machine].box.directory.to_s
          boxFile = env[:machine].box.name.to_s

          boxOVF = "file://#{boxDir}/#{boxFile}.ovf"

          # Still relying on ruby-progressbar because report_progress basically sucks.

          @logger.debug("OVF File: #{boxOVF}")


          env[:ui].info("Adding [#{env[:machine].box.name.to_s}]")

          dc = config.vcenter_cnx.serviceInstance.find_datacenter(config.datacenter_name) or fail "datacenter not found"

          root_vm_folder = dc.vmFolder
          vm_folder = root_vm_folder
          if config.template_folder_name.nil?
            vm_folder = root_vm_folder.traverse(config.template_folder_name, RbVmomi::VIM::Folder)
          end
          template_folder = root_vm_folder.traverse!(config.template_folder_name, RbVmomi::VIM::Folder)

          template_name = boxFile

          datastore = dc.find_datastore(config.datastore_name) or fail "datastore not found"
          computer = dc.find_compute_resource(config.computer_name) or fail "Host not found"

          network = computer.network.find{|x| x.name == config.network_name}

          deployer = CachedOvfDeployer.new(
            config.vcenter_cnx, network, computer, template_folder, vm_folder, datastore
          )
          template = deployer.upload_ovf_as_template(boxOVF, template_name, :run_without_interruptions => true)

          # FIXME: Progressbar??

        end


        def vcenter_check_inventory(env)
          # Will check each mandatory config value against the vcenter 
          # Instance and will setup the global environment config values
          config = env[:machine].provider_config
          dc = config.vcenter_cnx.serviceInstance.find_datacenter(config.datacenter_name) or fail "datacenter not found"

          if config.template_folder_name.nil?
            box_to_search = env[:machine].box.name.to_s
          else
            box_to_search = config.template_folder_name + "/" + env[:machine].box.name.to_s
          end

          @logger.debug("This is the box we're looking for: #{box_to_search}")

          config.template_id = dc.find_vm(box_to_search)

          if config.template_id.nil?
            env[:ui].warn("Template [#{env[:machine].box.name.to_s}] does not exist!")

            user_input = env[:ui].ask(
              "Would you like to upload the [#{env[:machine].box.name.to_s}] box?\nChoice (yes/no): "
            )

            if user_input.downcase == "yes" || user_input.downcase == "y" 
              env[:ui].info("Uploading [#{env[:machine].box.name.to_s}]...")
              vcenter_upload_box(env)
            else
              env[:ui].error("Template not uploaded, exiting...")

              # FIXME: wrong error message
              raise VagrantPlugins::VCenter::Errors::VCenterError, 
                    :message => "Catalog not available, exiting..."

            end
          else
            @logger.debug("Template found at #{box_to_search}")
          end
        end
      end
    end
  end
end
