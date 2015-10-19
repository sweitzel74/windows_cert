# encoding: utf-8
#
# Cookbook Name:: windows_cert
# Recipe:: test_pfx_resource
#

pfx_path = "#{Chef::Config[:file_cache_path]}/testkitchen.pfx"

cookbook_file pfx_path do
  source 'testkitchen.pfx'
  action :create
end

windows_cert_pfx 'testkitchen' do
  cert_file pfx_path
  cert_password 'secret'
  exportable true
  persist_key true
  storage_location 'UserKeySet'
  cert_store 'My'
  cert_root 'LocalMachine'
  action :install
end
