require 'pathname'
require 'vagrant/action/builder'

module VagrantPlugins
  module VCenter
    # Actions to be performed by the vagrant-vcenter provider.
    module Action
      include Vagrant::Action::Builtin

      # Vagrant commands
      # This action boots the VM, assuming the VM is in a state that requires
      # a bootup (i.e. not saved).
      def self.action_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use PowerOn
          b.use PrepareNFSSettings
          b.use Provision
          b.use SyncedFolders
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use Call, IsCreated do |env, b2|
            unless env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use action_halt
            b2.use action_start
          end
        end
      end

      # This action starts a VM, assuming it is already imported and exists.
      # A precondition of this action is that the VM exists.
      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use Call, IsRunning do |env, b2|
            # If the VM is running, then our work here is done, exit
            if env[:result]
              b2.use MessageAlreadyRunning
              next
            end
            b2.use Call, IsPaused do |env2, b3|
              if env2[:result]
                b3.use Resume
                next
              end
              b3.use action_boot
            end
          end
        end
      end

      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConnectvCenter
          b.use InventoryCheck

          # If the VM suspend, Resume first
          b.use Call, IsPaused do |env, b2|
            b2.use Resume if env[:result]

            # Only halt when VM is running.
            b2.use Call, IsRunning do |env2, b3|
              b3.use PowerOff if env2[:result]
            end
          end
        end
      end

      def self.action_suspend
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use Call, IsRunning do |env, b2|
            # If the VM is stopped, can't suspend
            if !env[:result]
              b2.use MessageCannotSuspend
            else
              b2.use Suspend
            end
          end
        end
      end

      def self.action_resume
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use Resume
        end
      end

      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, DestroyConfirm do |env, b2|
            if env[:result]
              b2.use ConfigValidate
              b2.use ConnectvCenter
              b2.use InventoryCheck
              b2.use Call, IsCreated do |env2, b3|
                unless env2[:result]
                  b3.use MessageNotCreated
                  next
                end
                b3.use Call, IsRunning do |env3, b4|
                # If the VM is running, must power off
                  b4.use action_halt if env3[:result]
                  b4.use Destroy
                end
              end
            else
              b2.use MessageWillNotDestroy
            end
          end
          # b.use DisconnectvCenter
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use Call, IsCreated do |env, b2|
            unless env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use PrepareNFSSettings
            b2.use Provision
            b2.use SyncedFolders
          end
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use ReadSSHInfo
        end
      end

      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use ReadState
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use Call, IsCreated do |env, b2|
            unless env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use AnnounceSSHExec
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use Call, IsCreated do |env, b2|
            unless env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use SSHRun
          end
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            b2.use HandleBox unless env[:result]
          end
          b.use ConnectvCenter
          b.use InventoryCheck
          b.use Call, IsCreated do |env, b2|
            b2.use BuildVM unless env[:result]
          end
          b.use action_start
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path('../action', __FILE__))
      autoload :AnnounceSSHExec,
               action_root.join('announce_ssh_exec')
      autoload :BuildVM,
               action_root.join('build_vm')
      autoload :ConnectvCenter,
               action_root.join('connect_vcenter')
      autoload :Destroy,
               action_root.join('destroy')
      autoload :DisconnectvCenter,
               action_root.join('disconnect_vcenter')
      autoload :ForwardPorts,
               action_root.join('forward_ports')
      autoload :InventoryCheck,
               action_root.join('inventory_check')
      autoload :IsCreated,
               action_root.join('is_created')
      autoload :IsPaused,
               action_root.join('is_paused')
      autoload :IsRunning,
               action_root.join('is_running')
      autoload :MessageAlreadyRunning,
               action_root.join('message_already_running')
      autoload :MessageCannotSuspend,
               action_root.join('message_cannot_suspend')
      autoload :MessageNotCreated,
               action_root.join('message_not_created')
      autoload :MessageWillNotDestroy,
               action_root.join('message_will_not_destroy')
      autoload :PowerOff,
               action_root.join('power_off')
      autoload :PowerOn,
               action_root.join('power_on')
      autoload :PrepareNFSSettings,
               action_root.join('prepare_nfs_settings')
      autoload :ReadSSHInfo,
               action_root.join('read_ssh_info')
      autoload :ReadState,
               action_root.join('read_state')
      autoload :Resume,
               action_root.join('resume')
      autoload :Suspend,
               action_root.join('suspend')
    end
  end
end
