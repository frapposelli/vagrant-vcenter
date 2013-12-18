require "securerandom"
require "etc"

module VagrantPlugins
  module VCenter
    module Action
      class BuildVM
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_vcenter::action::build_vm")
        end

        def call(env)

          # FIXME: we need to find a way to clean things up when a SIGINT get 
          # called... see env[:interrupted] in the vagrant code

          config = env[:machine].provider_config
          vmName = env[:machine].name

          dc = config.vcenter_cnx.serviceInstance.find_datacenter(config.datacenter_name) or abort "datacenter not found"

          if config.template_folder_name.nil?
            box_to_search = env[:machine].box.name.to_s
          else
            box_to_search = config.template_folder_name + "/" + env[:machine].box.name.to_s
          end

          computer = dc.find_compute_resource(config.computer_name) or fail "Host not found"
          rp = computer.resourcePool

          template = dc.find_vm(box_to_search) or abort "VM not found"

          if config.linked_clones
            @logger.debug("DOING LINKED CLONE!")
            # The API for linked clones is quite strange. We can't create a linked
            # straight from any VM. The disks of the VM for which we can create a
            # linked clone need to be read-only and thus VC demands that the VM we
            # are cloning from uses delta-disks. Only then it will allow us to
            # share the base disk.
            #
            # Thus, this code first create a delta disk on top of the base disk for
            # the to-be-cloned VM, if delta disks aren't used already.
            disks = template.config.hardware.device.grep(RbVmomi::VIM::VirtualDisk)
            disks.select { |x| x.backing.parent == nil }.each do |disk|
              spec = {
                :deviceChange => [
                  {
                    :operation => :remove,
                    :device => disk
                  },
                  {
                    :operation => :add,
                    :fileOperation => :create,
                    :device => disk.dup.tap { |x|
                      x.backing = x.backing.dup
                      x.backing.fileName = "[#{disk.backing.datastore.name}]"
                      x.backing.parent = disk.backing
                    },
                  }
                ]
              }
              template.ReconfigVM_Task(:spec => spec).wait_for_completion
            end

            relocateSpec = RbVmomi::VIM.VirtualMachineRelocateSpec(:diskMoveType => :moveChildMostDiskBacking, :pool => rp)
          else
            relocateSpec = RbVmomi::VIM.VirtualMachineRelocateSpec(:pool => rp)
          end

          @logger.debug("Relocate Spec: #{relocateSpec.pretty_inspect}")

          spec = RbVmomi::VIM.VirtualMachineCloneSpec(:location => relocateSpec,
                                             :powerOn => false,
                                             :template => false)

          @logger.debug("Spec: #{spec.pretty_inspect}")

          vm_target = "Vagrant-#{Etc.getlogin}-#{vmName}-#{Socket.gethostname.downcase}-#{SecureRandom.hex(4)}"

          @logger.debug("VM name: #{vm_target}")

          # FIXME: vm.parent brings us to the template folder, fix this with folder_path.

          root_vm_folder = dc.vmFolder
          vm_folder = root_vm_folder
          if !config.folder_name.nil?
            vm_folder = root_vm_folder.traverse(config.folder_name, RbVmomi::VIM::Folder)
          end


          @logger.debug("folder for VM: #{vm_folder}")

          template.CloneVM_Task(:folder => vm_folder, :name => vm_target, :spec => spec).wait_for_completion


          if config.folder_name.nil?
            vm_to_search = vm_target
          else
            vm_to_search = config.folder_name + "/" + vm_target
          end

          @logger.debug("VM to search: #{vm_to_search}")

          env[:machine].id = dc.find_vm(vm_to_search).config.uuid or abort "VM not found"

          @app.call env

        end
      end
    end
  end
end
