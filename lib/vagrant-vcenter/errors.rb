require 'vagrant'

module VagrantPlugins
  module VCenter
    module Errors
      class VCenterError < Vagrant::Errors::VagrantError
        error_namespace('vagrant_vcenter.errors')
      end
      class RsyncError < VCenterError
        error_key(:rsync_error)
      end

      class MkdirError < VCenterError
        error_key(:mkdir_error)
      end
      class VCenterOldVersion < VCenterError
        error_key(:vcenter_old_version)
      end
      class CatalogAddError < VCenterError
        error_key(:catalog_add_error)
      end
      class HostNotFound < VCenterError
        error_key(:host_not_found)
      end
      class HostRedirect < VCenterError
        error_key(:host_redirect)
      end
      class UnauthorizedAccess < VCenterError
        error_key(:unauthorized_access)
      end
      class StopVAppError < VCenterError
        error_key(:stop_vapp_error)
      end
      class ComposeVAppError < VCenterError
        error_key(:compose_vapp_error)
      end
      class InvalidNetSpecification < VCenterError
        error_key(:invalid_network_specification)
      end
      class ForwardPortCollision < VCenterError
        error_key(:forward_port_collision)
      end
      class SubnetErrors < VCenterError
        error_namespace('vagrant_vcenter.errors.subnet_errors')
      end
      class InvalidSubnet < SubnetErrors
        error_key(:invalid_subnet)
      end
      class SubnetTooSmall < SubnetErrors
        error_key(:subnet_too_small)
      end
      class RestError < VCenterError
        error_namespace('vagrant_vcenter.errors.rest_errors')
      end
      class ObjectNotFound < RestError
        error_key(:object_not_found)
      end
      class InvalidConfigError < RestError
        error_key(:invalid_config_error)
      end
      class InvalidStateError < RestError
        error_key(:invalid_state_error)
      end
      class SyncError < VCenterError
        error_key(:sync_error)
      end
    end
  end
end
