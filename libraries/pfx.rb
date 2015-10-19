# encoding: utf-8
#
# Cookbook Name:: windows_cert
# Library:: pfx
#

module WindowsCert
  # certificate module for installing PFX file into windows certificate store
  module Pfx
    def install_pfx_certificate(params = {})
      # The cert is installed via schedule tasks to workaround "delegated"
      # credential security issues triggered by the "pfx.import" call
      gen_script(params)
      create_task(params)
      run_task
      delete_task
      delete_temp_files
    end

    def gen_script(params)
      my_flags = build_flags(params).join(',')
      template script_file do
        source 'cert_script.ps1.erb'
        cookbook 'windows_cert'
        sensitive true
        variables my_flags: my_flags, params: params, out_file: out_file
        action :nothing
      end.run_action(:create)
    end

    def build_flags(params)
      storage_flags = []
      storage_flags.push('Exportable') if params[:exportable]
      storage_flags.push('PersistKeySet') if params[:persist_key]
      if params[:storage_location]
        storage_flags.push(params[:storage_location])
      else
        storage_flags.push('DefaultKeySet')
      end
      storage_flags
    end

    def script_file
      @script_file ||= "#{Chef::Config[:file_cache_path]}/cert_script.ps1"
    end

    def out_file
      @out_file ||= "#{Chef::Config[:file_cache_path]}/cert_script.out"
    end

    def create_task(params)
      windows_task task_name do
        user params[:admin_user]
        password params[:admin_password]
        cwd Chef::Config[:file_cache_path]
        command "powershell.exe -ExecutionPolicy RemoteSigned -File #{script_file}"
        run_level :highest
        action :nothing
      end.run_action(:create)
    end

    def task_name
      @task_name ||= DateTime.now.to_s.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')
    end

    def run_task
      windows_task task_name do
        action :nothing
      end.run_action(:run)
      wait_for_output
      check_result
    end

    # rubocop:disable Metrics/MethodLength
    def wait_for_output
      timeout = 0
      until File.exist?(out_file)
        if timeout < 18 # Allow up to 90 seconds to install
          timeout += 1
          Chef::Log.info('Waiting for cert install script to complete.')
          sleep(5)
        else
          Chef::Log.error('Install timeout: Task completion log not found.')
          Chef::Log.error('Install timeout: Aborting run.')
          fail
        end
      end
    end

    def check_result
      File.open(out_file, 'r') do |f|
        f.each_line do |line|
          Chef::Log.info(line)
          if line.include? 'Added cert to store.'
            new_resource.updated_by_last_action(true)
          end
        end
      end
    end

    def delete_task
      windows_task task_name do
        action :nothing
        force true
      end.run_action(:delete)
    end

    def delete_temp_files
      file script_file do
        backup false
        action :nothing
      end.run_action(:delete)
      file out_file do
        backup false
        action :nothing
      end.run_action(:delete)
    end
  end
end
