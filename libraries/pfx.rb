# encoding: utf-8
#
# Cookbook Name:: windows_cert
# Library:: pfx
#

module WindowsCert
  # certificate module for installing PFX file into windows certificate store
  module Pfx
    # rubocop:disable Metrics/MethodLength
    def install_pfx_certificate(params = {})
      powershell_script 'pfx_importer_powershell' do
        guard_interpreter :powershell_script
        cwd Chef::Config[:file_cache_path]
        code <<-EOH
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
          $store.add($pfx)
          $store.close()
        EOH
        not_if <<-EOH
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
          $store.close()
          if ($fcollection.Count -gt 0) {return $true}
          else {return $false}
        EOH
      end
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
