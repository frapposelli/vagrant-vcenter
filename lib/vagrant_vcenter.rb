require 'pathname'
require 'vagrant-vcenter/plugin'

module VagrantPlugins
  # Initialize the plugin.
  module VCenter
    lib_path = Pathname.new(File.expand_path('vagrant-vcenter', __dir__))
    autoload :Action, lib_path.join('action')
    autoload :Errors, lib_path.join('errors')

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('..', __dir__))
    end
  end
end
