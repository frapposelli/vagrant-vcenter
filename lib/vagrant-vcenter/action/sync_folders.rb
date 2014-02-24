# The MIT License (MIT)
# Copyright (c) 2013 Mitchell Hashimoto

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of  this software and associated documentation files (the "Software"), to
# deal in  the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do  so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

require 'log4r'
require 'vagrant/util/subprocess'
require 'vagrant/util/scoped_hash_override'
require 'vagrant/util/which'

module VagrantPlugins
  module VCenter
    module Action
      # This class syncs Vagrant folders using RSYNC, this code has been ported
      # from vagrant-aws (https://github.com/mitchellh/vagrant-aws)
      class SyncFolders
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_vcenter::action::sync_folders')
        end

        def call(env)
          @app.call(env)

          ssh_info = env[:machine].ssh_info

          unless Vagrant::Util::Which.which('rsync')
            env[:ui].warn(I18n.t('vagrant_vcenter.sync.rsync_not_found_warning',
                                 :side => 'host'))
            return
          end

          if env[:machine].communicate.execute('which rsync',
                                               :error_check => false) != 0
            env[:ui].warn(I18n.t('vagrant_vcenter.sync.rsync_not_found_warning',
                                 :side => 'guest'))
            return
          end

          env[:machine].config.vm.synced_folders.each do |id, data|
            data = scoped_hash_override(data, :vCenter)

            # Ignore disabled shared folders
            next if data[:disabled]

            hostpath  = File.expand_path(data[:hostpath], env[:root_path])
            guestpath = data[:guestpath]

            # Make sure there is a trailing slash on the host path to
            # avoid creating an additional directory with rsync
            hostpath = "#{hostpath}/" if hostpath !~ /\/$/

            # on windows rsync.exe requires cygdrive-style paths
            if Vagrant::Util::Platform.windows?
              hostpath = hostpath.gsub(/^(\w):/) { "/cygdrive/\1" }
            end

            env[:ui].info(I18n.t('vagrant_vcenter.sync.rsync_folder',
                                 :hostpath => hostpath,
                                 :guestpath => guestpath))

            # Create the host path if it doesn't exist and option flag is set
            if data[:create]
              begin
                FileUtils.mkdir_p(hostpath)
              rescue => err
                raise Errors::MkdirError,
                      :hostpath => hostpath,
                      :err => err
              end
            end

            # Create the guest path
            env[:machine].communicate.sudo("mkdir -p '#{guestpath}'")
            env[:machine].communicate.sudo(
              "chown -R #{ssh_info[:username]} '#{guestpath}'")

            # collect rsync excludes specified :rsync_excludes=>['path1',...]
            # in synced_folder options
            excludes = ['.vagrant/', 'Vagrantfile',
                        *Array(data[:rsync_excludes])].uniq

            # Rsync over to the guest path using the SSH info
            command = [
              'rsync', '--verbose', '--archive', '-z',
              *excludes.map { |e|['--exclude', e] }.flatten,
              '-e', "ssh -p #{ssh_info[:port]} -o StrictHostKeyChecking=no " +
              "#{ssh_key_options(ssh_info)}", hostpath,
              "#{ssh_info[:username]}@#{ssh_info[:host]}:#{guestpath}"]

            # we need to fix permissions when using rsync.exe on windows, see
            # http://stackoverflow.com/questions/5798807/rsync-permission-
            # denied-created-directories-have-no-permissions
            if Vagrant::Util::Platform.windows?
              command.insert(1, '--chmod', 'ugo=rwX')
            end

            r = Vagrant::Util::Subprocess.execute(*command)
            if r.exit_code != 0
              fail Errors::RsyncError,
                   :guestpath => guestpath,
                   :hostpath => hostpath,
                   :stderr => r.stderr
            end
          end
        end

        private

        def ssh_key_options(ssh_info)
          # Ensure that `private_key_path` is an Array (for Vagrant < 1.4)
          Array(ssh_info[:private_key_path]).map { |path| "-i '#{path}' " }.join
        end
      end
    end
  end
end
