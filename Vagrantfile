# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
	config.vm.box = "centos6-simple"
	config.vm.host_name = "mysql"
  	 config.vm.share_folder "myq_gadgets", "/myq_gadgets", "../myq_gadgets"

	config.vm.provision :puppet do |puppet|
		puppet.manifests_path = "manifests"
    	puppet.manifest_file  = "centos6.pp"
	end
end
