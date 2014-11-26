require 'vagrant'

module VagrantPlugins
  module VCenter
    module Errors
      # Initialize main error class.
      class VCenterError < Vagrant::Errors::VagrantError
        error_namespace('vagrant_vcenter.errors')
      end
      # Set key for Rsync errors.
      class RsyncError < VCenterError
        error_key(:rsync_error)
      end
      # Set key for Mkdir errors.
      class MkdirError < VCenterError
        error_key(:mkdir_error)
      end
      # Set key for VCenterOldVersion errors.
      class VCenterOldVersion < VCenterError
        error_key(:vcenter_old_version)
      end
      # Set key for CatalogAddError errors.
      class CatalogAddError < VCenterError
        error_key(:catalog_add_error)
      end
      # Set key for HostNotFound errors.
      class HostNotFound < VCenterError
        error_key(:host_not_found)
      end
      # Set key for HostRedirect errors.
      class HostRedirect < VCenterError
        error_key(:host_redirect)
      end
      # Set key for UnauthorizedAccess errors.
      class UnauthorizedAccess < VCenterError
        error_key(:unauthorized_access)
      end
      # Set key for StopVAppError errors.
      class StopVAppError < VCenterError
        error_key(:stop_vapp_error)
      end
      # Set key for ComposeVAppError errors.
      class ComposeVAppError < VCenterError
        error_key(:compose_vapp_error)
      end
      # Set key for InvalidNetSpecification errors.
      class InvalidNetSpecification < VCenterError
        error_key(:invalid_network_specification)
      end
      # Set key for ForwardPortCollision errors.
      class ForwardPortCollision < VCenterError
        error_key(:forward_port_collision)
      end
      # Set key for SubnetErrors errors.
      class SubnetErrors < VCenterError
        error_namespace('vagrant_Vcenter.errors.subnet_errors')
      end
      # Set key for InvalidSubnet errors.
      class InvalidSubnet < SubnetErrors
        error_key(:invalid_subnet)
      end
      # Set key for SubnetTooSmall errors.
      class SubnetTooSmall < SubnetErrors
        error_key(:subnet_too_small)
      end
      # Set key for RestError errors.
      class RestError < VCenterError
        error_namespace('vagrant_Vcenter.errors.rest_errors')
      end
      # Set key for ObjectNotFound errors.
      class ObjectNotFound < RestError
        error_key(:object_not_found)
      end
      # Set key for InvalidConfigError errors.
      class InvalidConfigError < RestError
        error_key(:invalid_config_error)
      end
      # Set key for InvalidStateError errors.
      class InvalidStateError < RestError
        error_key(:invalid_state_error)
      end
      # Set key for SyncError errors.
      class SyncError < VCenterError
        error_key(:sync_error)
      end
      # Set key for DatacenterNotFound errors.
      class DatacenterNotFound < VCenterError
        error_key(:datacenter_not_found)
      end
      # Set key for ComputeNotFound errors.
      class ComputeNotFound < VCenterError
        error_key(:compute_not_found)
      end
      # Set key for DatastoreNotFound errors.
      class DatastoreNotFound < VCenterError
        error_key(:datastore_not_found)
      end
      # Set key for NetworkNotFound errors.
      class NetworkNotFound < VCenterError
        error_key(:network_not_found)
      end
      # Set key for MachineNotRunning errors.
      class MachineNotRunning < VCenterError
        error_key(:machine_not_running)
      end
      # Set key for VMNotFound errors.
      class VMNotFound < VCenterError
        error_key(:vm_not_found)
      end
      # Set key for GuestCustomNotSupported
      class GuestCustomNotSupported < VCenterError
        error_key(:guest_custom_not_supported)
      end
    end
  end
end
