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
      ecommand = encode_command(params)
      windows_task "#{task_name}" do
        user "#{params[:admin_user]}"
        password "#{params[:admin_password]}"
        cwd Chef::Config[:file_cache_path]
        command "powershell.exe -EncodedCommand #{ecommand}"
        run_level :highest
      end
    end

    def run_task(task_name)
      windows_task "#{task_name}" do
        action :run
      end
    end

    def delete_task(task_name)
      windows_task "#{task_name}" do
        action :delete
      end
    end

    def task_name
      @task_name ||= Datetime.now.to_s.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')
    end

    # rubocop:disable Metrics/MethodLength
    def encode_command(params)
      ps_script = <<-EOH
        [String]$certPath = "#{params[:cert_file]}"
        [String]$pfxPass = "#{params[:cert_password]}"
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]`
        $flags = "#{build_flags(params).join(',')}"
        $pfx = new-object `
               System.Security.Cryptography.X509Certificates.X509Certificate2
        $pfx.import($certPath, $pfxPass, $flags)
        [String]$certStore = "#{params[:cert_store]}"
        [String]$certRoot = "#{params[:cert_root]}"
        $store = new-object `
                 System.Security.Cryptography.X509Certificates.X509Store( `
                 $certStore, $certRoot)
        $store.open("MaxAllowed")
        [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]`
        $fcollection = `
          [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]$store.Certificates.Find(`
          [System.Security.Cryptography.X509Certificates.X509FindType]"FindByThumbprint",`
          $pfx.Thumbprint,`
          $false)
        if ($fcollection.Count -eq 0) {$store.add($pfx)}
        $store.close()
      EOH
      ps_script.encode('UTF-16LE', 'UTF-8').Base64.strict_encode64
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
  end
end
