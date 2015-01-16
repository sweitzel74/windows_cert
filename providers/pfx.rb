# encoding: utf-8
#
# Cookbook Name:: windows_cert
# Provider:: pfx
#

include WindowsCert::Pfx

action :install do
  install_pfx_certificate(
    cert_file: @new_resource.cert_file,
    cert_password: @new_resource.cert_password,
    exportable: @new_resource.exportable,
    persist_key: @new_resource.persist_key,
    storage_location: @new_resource.storage_location,
    cert_store: @new_resource.cert_store,
    cert_root: @new_resource.cert_root
  )
end
