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
            'vagrant_vcenter::action::inventory_check'
          )
        end

        def call(env)
          vcenter_check_inventory(env)
          @app.call env
        end

        def vcenter_upload_box(env)
          cfg = env[:machine].provider_config

          if env[:machine].box.name.include? '/'
            box_file = env[:machine].box.name.rpartition('/').last
            box_name = env[:machine].box.name.gsub(/\//, '-')
          else
            box_file = env[:machine].box.name
            box_name = box_file
          end

          if cfg.template_folder_name.nil?
            box_to_search = box_name
            cfg.template_folder = cfg.vmfolder
          else
            box_to_search = cfg.template_folder_name + '/' + box_name
            cfg.template_folder = cfg.vmfolder.traverse!(
              cfg.template_folder_name,
              RbVmomi::VIM::Folder
            )
          end

          @logger.debug("Checking for box: #{box_to_search}...")

          # Check for the template object and add it the provider config
          cfg.template = cfg.datacenter.find_vm(box_to_search)

          if cfg.template.nil?
            # Roll a dice to get a winner in the race.
            sleep_time = rand * (3 - 1) + 1
            @logger.debug("Sleeping #{sleep_time} to avoid race conditions.")
            sleep(sleep_time)

            box_dir = env[:machine].box.directory
            box_ovf = "file://#{box_dir}/#{box_file}.ovf"

            env[:ui].info("Uploading [#{box_name}]...")
            @logger.debug("OVF File: #{box_ovf}")

            deployer = CachedOvfDeployer.new(
              cfg.vcenter_cnx,
              cfg.network,
              cfg.compute,
              cfg.template_folder,
              cfg.vmfolder,
              cfg.datastore
            )

            deployer_opts = {
              :run_without_interruptions  => true,
              :simple_vm_name             => true
            }

            deployer.upload_ovf_as_template(
              box_ovf,
              box_name,
              deployer_opts
            )

            # Re Fetch the template object and add it the provider config
            cfg.template = cfg.datacenter.find_vm(box_to_search)
          else
            @logger.debug('Box already exists at target endpoint')
          end

          # FIXME: Progressbar??
        end

        def vcenter_check_inventory(env)
          # Will check each mandatory config value against the vcenter
          # Instance and will setup the global environment config values

          cfg = env[:machine].provider_config
          cnx = cfg.vcenter_cnx

          # Fetch Datacenter handle and add it to provider config
          cfg.datacenter = cnx.serviceInstance.find_datacenter(
            cfg.datacenter_name
          ) or fail Errors::DatacenterNotFound,
                    :datacenter_name => cfg.datacenter_name

          # Fetch vmFolder handle for the specific Datacenter and add it to
          # provider config
          cfg.vmfolder = cfg.datacenter.vmFolder

          # Fetch compute resource handle and add it to the provider config
          cfg.compute = cfg.datacenter.find_compute_resource(
            cfg.compute_name
          ) or fail Errors::ComputeNotFound,
                    :compute_name => cfg.compute_name

          # Fetch datastore handle and add it to the provider config
          cfg.datastore = cfg.datacenter.find_datastore(
            cfg.datastore_name
          ) or fail Errors::DatastoreNotFound,
                    :datastore_name => cfg.datastore_name

          # Fetch network portgroup handle and add it to the provider config
          cfg.network = cfg.compute.network.find {
            |x| x.name == cfg.network_name
          } or fail Errors::NetworkNotFound,
                    :network_name => cfg.network_name

          # Use this method to take care of the template/boxes
          vcenter_upload_box(env)
        end
      end
    end
  end
end
