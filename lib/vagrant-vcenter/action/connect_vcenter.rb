require 'rbvmomi'
require 'log4r'

module VagrantPlugins
  module VCenter
    module Action
      # This class connects the vagrant-vcenter provider to vCenter.
      class ConnectvCenter
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new(
                      'vagrant_vcenter::action::connect_vCenter')
        end

        def call(env)
          config = env[:machine].provider_config
          # Avoid recreating a new session each time.
          unless config.vcenter_cnx
            @logger.info('Connecting to vCenter...')

            @logger.debug("config.hostname: #{config.hostname}")
            @logger.debug("config.username: #{config.username}")
            @logger.debug('config.password: <hidden>')

            # FIXME: fix the insecure flag, catch the exception
            config.vcenter_cnx = RbVmomi::VIM.connect(
                                  host: config.hostname,
                                  user: config.username,
                                  password: config.password,
                                  insecure: true)
          end
          @app.call env
        end
      end
    end
  end
end
