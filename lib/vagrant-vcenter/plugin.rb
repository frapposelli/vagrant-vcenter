begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant vCenter plugin must be run within Vagrant.'
end

if Vagrant::VERSION < '1.5.0'
  fail 'The Vagrant vCenter plugin is only compatible with Vagrant 1.5+'
end

module VagrantPlugins
  module VCenter
    # Initialize Vagrant Plugin
    class Plugin < Vagrant.plugin('2')
      name 'VMware vCenter Provider'
      description 'Allows Vagrant to manage machines with VMware vCenter (R)'

      config(:vcenter, :provider) do
        require_relative 'config'
        Config
      end

      provider(:vcenter) do
        setup_logging
        setup_i18n

        # Return the provider
        require_relative 'provider'
        Provider
      end

      # Add vagrant share support
      provider_capability('vcenter', 'public_address') do
        require_relative 'cap/public_address'
        Cap::PublicAddress
      end

      def self.setup_i18n
        I18n.load_path << File.expand_path('locales/en.yml',
                                           VCenter.source_root)
        I18n.reload!
      end

      # This sets up our log level to be whatever VAGRANT_LOG is.
      def self.setup_logging
        require 'log4r'

        level = nil
        begin
          level = Log4r.const_get(ENV['VAGRANT_LOG'].upcase)
        rescue NameError
          # This means that the logging constant wasn't found,
          # which is fine. We just keep `level` as `nil`. But
          # we tell the user.
          level = nil
        end

        # Some constants, such as 'true' resolve to booleans, so the
        # above error checking doesn't catch it. This will check to make
        # sure that the log level is an integer, as Log4r requires.
        level = nil unless level.is_a?(Integer)

        # Set the logging level on all 'vagrant' namespaced
        # logs as long as we have a valid level.
        if level
          logger = Log4r::Logger.new('vagrant_vcenter')
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
        end
      end
    end
  end
end
