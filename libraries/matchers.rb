# encoding: utf-8
#
# Cookbook Name:: windows_cert
# Library:: matchers
#
if defined?(ChefSpec)
  def install_windows_cert_pfx(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:windows_cert_pfx,
                                            :install,
                                            resource_name)
  end
end
