require 'pathname'

require 'vagrant/action/builder'

module VagrantPlugins
  module Openstack
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action is called to destroy the remote machine.
      def self.action_destroy
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, ReadState do |env, b2|
            if env[:machine_state_id] == :not_created
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            else
              b2.use(ProvisionerCleanup, :before)
              b2.use SnapshotCleanup if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
              b2.use DeleteServer
              b2.use DeleteStack
            end
          end
        end
      end

      # This action is called when `vagrant provision` is called.
      def self.action_provision
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, ReadState do |env, b2|
            if env[:machine_state_id] == :not_created
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            else
              if env[:machine].provider_config.meta_args_support
                b2.use ProvisionWrapper
              else
                b2.use Provision
              end
              if env[:machine].provider_config.use_legacy_synced_folders
                env[:machine].ui.warn I18n.t('vagrant_openstack.config.sync_folders_deprecated')
                b2.use SyncFolders
              else
                # Standard Vagrant implementation.
                b2.use SyncedFolders
              end
            end
          end
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use ReadSSHInfo
        end
      end

      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        new_builder.tap do |b|
          b.use HandleBox
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use ReadState
        end
      end

      def self.action_ssh
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, ReadState do |env, b2|
            if env[:machine_state_id] == :not_created
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            else
              b2.use SSHExec
            end
          end
        end
      end

      def self.action_ssh_run
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, ReadState do |env, b2|
            if env[:machine_state_id] == :not_created
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            else
              b2.use SSHRun
            end
          end
        end
      end

      def self.action_up
        new_builder.tap do |b|
          b.use HandleBox
          b.use ConfigValidate
          b.use ConnectOpenstack

          b.use Call, ReadState do |env, b2|
            case env[:machine_state_id]
            when :not_created
              ssh_disabled = env[:machine].provider_config.ssh_disabled
              unless ssh_disabled
                if env[:machine].provider_config.meta_args_support
                  b2.use ProvisionWrapper
                else
                  b2.use Provision
                end
              end

              if env[:machine].provider_config.use_legacy_synced_folders
                env[:machine].ui.warn I18n.t('vagrant_openstack.config.sync_folders_deprecated')
                b2.use SyncFolders
              else
                # Standard Vagrant implementation.
                b2.use SyncedFolders
              end

              b2.use CreateStack
              b2.use CreateServer
              b2.use Message, I18n.t('vagrant_openstack.ssh_disabled_provisioning') if ssh_disabled
              unless ssh_disabled
                # Handle legacy ssh_timeout option
                timeout = env[:machine].provider_config.ssh_timeout
                unless timeout.nil?
                  env[:machine].ui.warn I18n.t('vagrant_openstack.config.ssh_timeout_deprecated')
                  env[:machine].config.vm.boot_timeout = timeout
                end

                b2.use WaitForCommunicator
              end
            when :shutoff
              b2.use StartServer
            when :suspended
              b2.use Resume
            else
              b2.use Message, I18n.t('vagrant_openstack.already_created')
            end
          end
        end
      end

      def self.action_halt
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, ReadState do |env, b2|
            if env[:machine_state_id] == :not_created
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            else
              b2.use StopServer
            end
          end
        end
      end

      # This is the action that is primarily responsible for suspending
      # the virtual machine.
      # Vm cannot be suspended when the machine_state_id is not "active" (typically a task is ongoing)
      def self.action_suspend
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, ReadState do |env, b2|
            case env[:machine_state_id]
            when :not_created
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            when :suspended
              b2.use Message, I18n.t('vagrant_openstack.already_suspended')
            when :active
              b2.use Suspend
            else
              b2.use Message, I18n.t('vagrant_openstack.ongoing_task')
            end
          end
        end
      end

      # This is the action that is primarily responsible for resuming
      # suspended machines.
      # Vm cannot be resumed when the machine_state_id is not suspended.
      def self.action_resume
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, ReadState do |env, b2|
            case env[:machine_state_id]
            when :not_created
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            when :suspended
              b2.use Resume
            else
              b2.use Message, I18n.t('vagrant_openstack.not_suspended')
            end
          end
        end
      end

      def self.action_reload
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, ReadState do |env, b2|
            case env[:machine_state_id]
            when :not_created
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            when :suspended
              b2.use Resume
              b2.use WaitForServerToBeActive
              b2.use StopServer
              b2.use WaitForServerToStop
              b2.use StartServer
            when :shutoff
              b2.use StartServer
            else
              b2.use StopServer
              b2.use WaitForServerToStop
              b2.use StartServer
            end
          end
        end
      end

      # TODO: Remove the if guard when Vagrant 1.8.0 is the minimum version.
      # rubocop:disable IndentationWidth
      if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
      def self.action_snapshot_delete
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            else
              b2.use SnapshotDelete
            end
          end
        end
      end

      def self.action_snapshot_list
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            else
              b2.use SnapshotList
            end
          end
        end
      end

      def self.action_snapshot_restore
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t('vagrant_openstack.not_created')
              next
            end

            b2.use SnapshotRestore
            b2.use WaitForServerToBeActive
            b2.use WaitForCommunicator

            b2.use Call, IsEnvSet, :snapshot_delete do |env2, b3|
              # Used by vagrant push/pop
              b3.use action_snapshot_delete if env2[:result]
            end

            b2.use action_provision
          end
        end
      end

      def self.action_snapshot_save
        new_builder.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenstack
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t('vagrant_openstack.not_created')
            else
              b2.use SnapshotSave
            end
          end
        end
      end
      end # Vagrant > 1.8.0 guard
      # rubocop:enable IndentationWidth

      # The autoload farm
      action_root = Pathname.new(File.expand_path('../action', __FILE__))
      autoload :Message, action_root.join('message')
      autoload :ConnectOpenstack, action_root.join('connect_openstack')
      autoload :CreateServer, action_root.join('create_server')
      autoload :CreateStack, action_root.join('create_stack')
      autoload :DeleteStack, action_root.join('delete_stack')
      autoload :DeleteServer, action_root.join('delete_server')
      autoload :StopServer, action_root.join('stop_server')
      autoload :StartServer, action_root.join('start_server')
      autoload :ReadSSHInfo, action_root.join('read_ssh_info')
      autoload :ReadState, action_root.join('read_state')
      autoload :SyncFolders, action_root.join('sync_folders')
      autoload :Suspend, action_root.join('suspend')
      autoload :Resume, action_root.join('resume')
      autoload :ProvisionWrapper, action_root.join('provision')
      autoload :WaitForServerToStop, action_root.join('wait_stop')
      autoload :WaitForServerToBeActive, action_root.join('wait_active')
      # TODO: Remove the if guard when Vagrant 1.8.0 is the minimum version.
      # rubocop:disable IndentationWidth
      if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
      autoload :SnapshotCleanup, action_root.join('snapshot_cleanup')
      autoload :SnapshotDelete, action_root.join('snapshot_delete')
      autoload :SnapshotList, action_root.join('snapshot_list')
      autoload :SnapshotRestore, action_root.join('snapshot_restore')
      autoload :SnapshotSave, action_root.join('snapshot_save')
      end
      # rubocop:enable IndentationWidth

      private

      def self.new_builder
        Vagrant::Action::Builder.new
      end
    end
  end
end
