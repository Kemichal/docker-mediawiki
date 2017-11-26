# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end
  config.vm.box = "ubuntu/xenial64"
  config.vm.network "forwarded_port", guest: 80, host: 8095, protocol: "tcp"
  config.vm.network "forwarded_port", guest: 8080, host: 8096, protocol: "tcp"
  config.vm.provision :docker
  config.vm.provision :docker_compose
  config.vm.provision "shell", path: "vagrant/provision.sh"
end
