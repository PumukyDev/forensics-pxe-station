Vagrant.configure("2") do |config|
  config.vm.box='clink15/pxe'

  config.vm.network "private_network", type: "dhcp"

  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--cpus", 8]
    v.customize ["modifyvm", :id, "--memory", 14120]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--natdnsproxy1", "on"]

    v.customize ["modifyvm", :id, "--cableconnected1", "on"]
    v.gui = true
  end

  config.vm.synced_folder '.', '/vagrant', disabled: true
end