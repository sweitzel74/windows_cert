# encoding: utf-8
#
# Cookbook Name:: windows_cert
# Resource:: pfx
#

actions :install
default_action :install

attribute :cert_file, kind_of: String, required: true
attribute :cert_password, kind_of: String, required: false
attribute :exportable, \
          kind_of: [TrueClass, FalseClass], \
          required: false, default: false
attribute :persist_key, \
          kind_of: [TrueClass, FalseClass], \
          required: false, default: false
attribute :storage_location, kind_of: String, required: false
attribute :cert_store, kind_of: String, required: true
attribute :cert_root, kind_of: String, required: true
