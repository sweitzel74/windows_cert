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
      create_task(params)
      run_task(task_name)
      delete_task(task_name)
    end

    def create_task(params)
      cert_path_and_filename = gen_temp_ps_script(params)
      windows_task "#{task_name}" do
        user "#{params[:admin_user]}"
        password "#{params[:admin_password]}"
        cwd Chef::Config[:file_cache_path]
        command "powershell.exe -ExecutionPolicy RemoteSigned -File #{cert_path_and_filename}"
        run_level :highest
      end
    end

    def run_task(task_name)
      windows_task "#{task_name}" do
        action :run
      end
      check_script_output("#{Chef::Config[:file_cache_path]}/cert_script.out")
    end

    def delete_task(task_name)
      windows_task "#{task_name}" do
        action :delete
        force true
      end
    end

    def task_name
      @task_name ||= DateTime.now.to_s.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')
    end

    # rubocop:disable Metrics/MethodLength
    def gen_temp_ps_script(params)
      my_flags = build_flags(params).join(',')
      out_file = "#{Chef::Config[:file_cache_path]}/cert_script.out"
      my_file = "#{Chef::Config[:file_cache_path]}/cert_script.ps1"
      template my_file do
        source 'cert_script.ps1.erb'
        cookbook 'windows_cert'
        sensitive true
        variables my_flags: my_flags, params: params, out_file: out_file
        action :create
      end
      my_file
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

    def check_script_output(script_outfile)
      ruby_block 'check_script_output' do
        block do
          until File.exist?(script_outfile)
            Chef::Log.info('Waiting for cert install script to complete.')
            sleep(5)
          end
         File.open(script_outfile, 'r') do |f|
           f.each_line do |line|
             Chef::Log.info(line)
             if line.include? 'Added cert to store.'
               new_resource.updated_by_last_action(true)
             else
               new_resource.updated_by_last_action(false)
             end
           end
         end
        end
      end
    end
  end
end
