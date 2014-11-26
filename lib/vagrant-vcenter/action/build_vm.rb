module VagrantPlugins
  module VCenter
    module Action
      # This class builds the VM to be used by Vagrant.
      class BuildVM
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::build_vm')
        end

        def call(env)
          # FIXME: we need to find a way to clean things up when a SIGINT get
          # called... see env[:interrupted] in the vagrant code

          cfg = env[:machine].provider_config
          vm_name = env[:machine].name

          if env[:machine].box.name.include? '/'
            # box_file = env[:machine].box.name.rpartition('/').last
            box_name = env[:machine].box.name.gsub(/\//, '-')
          else
            box_file = env[:machine].box.name
            box_name = box_file
          end

          if cfg.template_folder_name.nil?
            box_to_search = box_name
          else
            box_to_search = cfg.template_folder_name + '/' + box_name
          end

          if cfg.resourcepool_name
            cfg.compute_rp = compute.resourcePool.resourcePool.find {
              |f| f.name == cfg.resourcepool_name
            }
          else
            cfg.compute_rp = cfg.compute.resourcePool
          end

          template = cfg.datacenter.find_vm(box_to_search) or
                     fail Errors::VMNotFound,
                          :vm_name => box_to_search

          if cfg.linked_clones
            @logger.debug('DOING LINKED CLONE!')
            # The API for linked clones is quite strange. We can't create a
            # linked straight from any VM. The disks of the VM for which we can
            # create a linked clone need to be read-only and thus VC demands
            # that the VM we are cloning from uses delta-disks. Only then it
            # will allow us to share the base disk.
            #
            # Thus, this code first create a delta disk on top of the base disk
            # for the to-be-cloned VM, if delta disks aren't used already.
            disks = template.config.hardware.device.grep(
              RbVmomi::VIM::VirtualDisk
            )

            disks.select { |x| x.backing.parent.nil? }.each do |disk|
              spec = {
                :deviceChange => [
                  {
                    :operation  => :remove,
                    :device     => disk
                  },
                  {
                    :operation      => :add,
                    :fileOperation  => :create,
                    :device         => disk.dup.tap do |x|
                      x.backing = x.backing.dup
                      x.backing.fileName = "[#{disk.backing.datastore.name}]"
                      x.backing.parent = disk.backing
                    end
                  }
                ]
              }
              template.ReconfigVM_Task(:spec => spec).wait_for_completion
            end

            relocate_spec = RbVmomi::VIM.VirtualMachineRelocateSpec(
              :diskMoveType => :moveChildMostDiskBacking,
              :pool         => cfg.compute_rp
            )
          else
            relocate_spec = RbVmomi::VIM.VirtualMachineRelocateSpec(
              :pool => cfg.compute_rp
            )
          end

          @logger.debug("Relocate Spec: #{relocate_spec.pretty_inspect}")

          spec = RbVmomi::VIM.VirtualMachineCloneSpec(
            :location   => relocate_spec,
            :powerOn    => false,
            :template   => false
          )

          if cfg.vm_network_name || cfg.num_cpu || cfg.memory
            config_spec = RbVmomi::VIM.VirtualMachineConfigSpec
            config_spec.numCPUs = cfg.num_cpu if cfg.num_cpu
            config_spec.memoryMB = cfg.memory if cfg.memory

            if cfg.vm_network_name
              card = template.config.hardware.device.grep(
                RbVmomi::VIM::VirtualEthernetCard
              ).first or abort 'could not find network card to customize'

              if cfg.vm_network_type == 'DistributedVirtualSwitchPort'
                switch_port =
                RbVmomi::VIM.DistributedVirtualSwitchPortConnection(
                  :switchUuid   => cfg.network.config.distributedVirtualSwitch.uuid,
                  :portgroupKey => cfg.network.key
                )
                card.backing = RbVmomi::VIM.VirtualEthernetCardDistributedVirtualPortBackingInfo(
                  :port => switch_port
                )
              end

              dev_spec = RbVmomi::VIM.VirtualDeviceConfigSpec(
                :device     => card,
                :operation  => 'edit'
              )
              config_spec.deviceChange = [dev_spec]
            end

            spec.config = config_spec
          end

          if cfg.enable_vm_customization
            public_networks = env[:machine].config.vm.networks.select {
              |n| n[0].eql? :public_network
            }

            network_spec = public_networks.first[1] unless public_networks.empty?

            @logger.debug("This is our network #{public_networks.inspect}")

            if network_spec
              # Check for sanity and validation of network parameters.
              if (network_spec[:ip] && !network_spec[:netmask]) ||
                 (!network_spec[:ip] && network_spec[:netmask])
                fail Errors::WrongNetworkSpec
              end

              global_ip_settings = RbVmomi::VIM.CustomizationGlobalIPSettings(
                :dnsServerList => network_spec[:dns_server_list],
                :dnsSuffixList => network_spec[:dns_suffix_list]
              )

              # if no ip and no netmask, let's default to dhcp
              if !network_spec[:ip] && !network_spec[:netmask]
                adapter = RbVmomi::VIM.CustomizationIPSettings(
                  :ip => RbVmomi::VIM.CustomizationDhcpIpGenerator()
                )
              else
                adapter = RbVmomi::VIM.CustomizationIPSettings(
                  :gateway    => [network_spec[:gateway]],
                  :ip         => RbVmomi::VIM.CustomizationFixedIp(
                      :ipAddress => network_spec[:ip]
                  ),
                  :subnetMask => network_spec[:netmask]
                )
              end

              nic_map = [
                RbVmomi::VIM.CustomizationAdapterMapping(:adapter => adapter)
              ]
            end

            if cfg.prep_type.downcase == 'linux'
              prep = RbVmomi::VIM.CustomizationLinuxPrep(
                :domain   => env[:machine].name.to_s.sub(/^[^.]+\./, ''),
                :hostName => RbVmomi::VIM.CustomizationFixedName(
                  :name => env[:machine].name.to_s.split('.')[0]
                )
              )
            elsif cfg.prep_type.downcase == 'windows'
              prep = RbVmomi::VIM.CustomizationSysprep(
                :guiUnattended => RbVmomi::VIM.CustomizationGuiUnattended(
                  :autoLogon      => false,
                  :autoLogonCount => 0,
                  :timeZone       => 004
                ),
                :identification => RbVmomi::VIM.CustomizationIdentification(),
                :userData => RbVmomi::VIM.CustomizationUserData(
                  :computerName => RbVmomi::VIM.CustomizationFixedName(
                    :name => env[:machine].name.to_s.split('.')[0]
                  ),
                  :fullName     => 'Vagrant',
                  :orgName      => 'Vagrant',
                  :productId    => 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
                )
              )
            else
              fail Errors::GuestCustomNotSupported,
                   :type => cfg.prep_type
            end

            if prep && network_spec
              # If prep and network specification are present,
              # -> Do a full config
              cust_spec = RbVmomi::VIM.CustomizationSpec(
                :globalIPSettings => global_ip_settings,
                :identity         => prep,
                :nicSettingMap    => nic_map
              )

              spec.customization = cust_spec

            elsif prep && !network_spec
              # If no network specifications, default to dhcp
              global_ip_settings = RbVmomi::VIM.CustomizationGlobalIPSettings(
                :dnsServerList => [],
                :dnsSuffixList => []
              )

              adapter = RbVmomi::VIM.CustomizationIPSettings(
                :ip => RbVmomi::VIM.CustomizationDhcpIpGenerator()
              )

              nic_map = [
                RbVmomi::VIM.CustomizationAdapterMapping(:adapter => adapter)
              ]

              cust_spec = RbVmomi::VIM.CustomizationSpec(
                :globalIPSettings => global_ip_settings,
                :identity         => prep,
                :nicSettingMap    => nic_map
              )

              spec.customization = cust_spec
            end

            @logger.debug("Spec: #{spec.pretty_inspect}")
          end

          @logger.debug("disable_auto_vm_name: #{cfg.disable_auto_vm_name}")

          # Not recommended in a vSphere environment where VM names might
          # conflict a lot if used in the same vm folder namespace
          if cfg.disable_auto_vm_name == true
            vm_target = vm_name
          else
            vm_target = "Vagrant-#{Etc.getlogin}-" +
                        "#{vm_name}-#{Socket.gethostname.downcase}-" +
                        "#{SecureRandom.hex(4)}"
          end

          @logger.debug("VM name: #{vm_target}")

          # FIXME: vm.parent brings us to the template folder, fix this with
          # folder_path.

          vm_folder = cfg.vmfolder
          unless cfg.folder_name.nil?
            begin
              # Better ask for forgiveness than permission ;-)
              @logger.debug("Creating folder #{cfg.folder_name}.")
              vm_folder = cfg.vmfolder.traverse(
                cfg.folder_name,
                RbVmomi::VIM::Folder,
                create = true
              )
            # FIXME: we should trap the correct exception
            rescue RbVmomi::Fault
              # if somebody else created the folder already...
              @logger.debug("Folder #{cfg.folder_name} already exists.")
              vm_folder = cfg.vmfolder.traverse(
                cfg.folder_name,
                RbVmomi::VIM::Folder
              )
            end
          end
          @logger.debug("folder for VM: #{vm_folder}")

          env[:ui].info('Creating VM...')

          template.CloneVM_Task(
            :folder => vm_folder,
            :name   => vm_target,
            :spec   => spec
          ).wait_for_completion

          if cfg.folder_name.nil?
            vm_to_search = vm_target.to_s
          else
            vm_to_search = cfg.folder_name + '/' + vm_target.to_s
          end

          @logger.debug("VM to search: #{vm_to_search}")

          env[:machine].id = cfg.datacenter.find_vm(
            vm_to_search
          ).config.uuid or fail Errors::VMNotFound,
                                :vm_name => vm_to_search

          @app.call env
        end
      end
    end
  end
end
