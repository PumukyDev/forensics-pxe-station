# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.box_check_update = false
  config.ssh.insert_key = false

  config.vm.provider :virtualbox do |vb|
    vb.memory = 256
    vb.cpus = 1
  end

  config.vm.define "test" do |s|
    s.vm.hostname = "test"

    s.vm.network "forwarded_port", guest: 22, host: 2222, auto_correct: true

    s.vm.network "private_network",
                 type: "dhcp",
                 virtualbox__intnet: "vboxnet2"

    s.vm.provider :virtualbox do |vb|
      vb.memory = 512
      vb.cpus = 1
    end
  end
end
