module VagrantPlugins
  module VCenter
    module Action
      # This class connects the vagrant-vcenter provider to vCenter.
      class ConnectvCenter
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new(
            'vagrant_vcenter::action::connect_vcenter'
          )
        end

        def call(env)
          cfg = env[:machine].provider_config

          # Avoid recreating a new session each time.
          unless cfg.vcenter_cnx
            @logger.info('Connecting to vCenter...')

            @logger.debug("hostname: #{cfg.hostname}")
            @logger.debug("username: #{cfg.username}")
            @logger.debug('password: <hidden>')

            # FIXME: fix the insecure flag, catch the exception
            cfg.vcenter_cnx = RbVmomi::VIM.connect(
              host: cfg.hostname,
              user: cfg.username,
              password: cfg.password,
              insecure: true
            )

          end
          @app.call env
        end
      end
    end
  end
end
