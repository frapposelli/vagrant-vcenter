require 'rbvmomi'

module VagrantPlugins
  module VCenter
    module Action
      class ConnectvCenter
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new(
            'vagrant_vcenter::action::connect_vCenter'
          )
        end

        def call(env)
          config = env[:machine].provider_config

          if !config.vcenter_cnx
            @logger.info('Connecting to vCenter...')

            @logger.debug("config.hostname    : #{config.hostname}")
            @logger.debug("config.username    : #{config.username}")
            @logger.debug("config.password    : #{config.password}")

            # Create the vCenter-rest connection object with the configuration
            # information.

            # FIXME: fix the insecure flag, catch the exception
            config.vcenter_cnx = RbVmomi::VIM.connect(
              host: config.hostname,
              user: config.username,
              password: config.password,
              insecure: true
            )
          end

          @app.call env
        end
      end
    end
  end
end
