module VagrantPlugins
  module VCenter
    module Action
      # This class disconnects the vagrant-vcenter provider from vCenter.
      class DisconnectvCenter
        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new(
            'vagrant_vcenter::action::disconnect_vcenter'
          )
        end

        def call(env)
          @logger.info('Disconnecting from vCenter ...')

          cfg = env[:machine].provider_config

          if cfg.vcenter_cnx
            cfg.vcenter_cnx.close
            @logger.info('Succesfully disconnected from vCenter...')
          else
            @logger.info('No session active')
          end

          @app.call env
        end
      end
    end
  end
end
