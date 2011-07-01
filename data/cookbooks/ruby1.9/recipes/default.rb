# Cookbook Name:: ruby1.9
# Recipe:: default
#
# Copyright 2011, Cloudspace
#
# All rights reserved - Do Not Redistribute

include_recipe "build-essential"

%w(libssl-dev libreadline5-dev zlib1g-dev libxml2-dev libxslt1-dev).each do |pkg|
	package pkg do
		action :install
	end
end

bash "installing ruby 1.9.2" do 
	user "root"
	cwd "/tmp"
	code <<-EOC
		wget ftp://ftp.ruby-lang.org//pub/ruby/1.9/ruby-1.9.2-p180.tar.gz
		tar -xvzf ruby-1.9.2-p180.tar.gz
		cd ruby-1.9.2-p180/
		./configure
		make && make install
	EOC
	not_if do
		%x(ruby -v).strip.include? "ruby 1.9.2"
	end
end

template "/etc/profile.d/path.sh" do
 path "/etc/profile.d/path.sh"
 source "path.sh.erb"
 mode "0644"
 owner "root"
 group "root"
end

bash "install rubygems from source" do
  user "root"
  cwd "/tmp"
  code <<-EOC
    wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.5.tgz
    tar xzvf rubygems-1.8.5.tgz
    cd rubygems-1.8.5
    ruby setup.rb
  EOC
  # not_if "which gem"
end

bash "update rubygems to latest" do
  user "root"
  code "gem update --system"
end

