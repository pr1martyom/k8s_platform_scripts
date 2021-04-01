# -*- mode: ruby -*-
# vi: set ft=ruby :

# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version '>= 1.6.0'
VAGRANTFILE_API_VERSION = '2'

# Require 'yaml' module
require 'yaml'

# Read YAML file with VM details (box, CPU, RAM, IP addresses)
# Edit machines.yml to change VM configuration details
machines = YAML.load_file(File.join(File.dirname(__FILE__), ENV['SIZE']))

# # Inline script applies to all nodes

$configureBox = <<-SCRIPT
    # install python-netaddr
    yum install python-netaddr -y
    setenforce 0
    yum install sshpass -y
    yum install curl -y
    yum install net-tools -y
    yum install nc -y
SCRIPT

unless Vagrant.has_plugin?("vagrant-host-shell")
	system('vagrant plugin install vagrant-host-shell')
	system('vagrant plugin install vagrant-vbguest --plugin-version 0.21')
	raise("Plugin installed. Run command again.");
end

# #  Inline script applies to master nodes only
# # Create and configure the VMs
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
   config.vagrant.plugins = "vagrant-host-shell"
# #    config.vagrant.plugins = "trigger"
    #Always use Vagrant's default insecure key
    config.ssh.insert_key = true
    machines.each do |machine|
        config.vm.define machine['box']['name'] do |srv|
            srv.vm.synced_folder '.', '/vagrant', disabled: true
            srv.vm.synced_folder "/shared-data/kube-data", "/shared-data", mount_options: ["dmode=775,fmode=777"]
            srv.vm.box = machine['box']['img']
            srv.vm.box_version = machine['box']['version']
            srv.vm.hostname = machine['box']['name']
            srv.vm.network "public_network", bridge: "k8s-bridge", ip: machine['box']['eth1']
            srv.ssh.forward_agent = true

            config.vm.provider "virtualbox" do |v|
                v.name = machine['box']['name']
                v.customize ["modifyvm", :id, "--groups", "/k8s lab"]
                v.customize ["modifyvm", :id, "--memory", machine['box']['mem']]
                v.customize ["modifyvm", :id, "--cpus", machine['box']['cpu']]
            end
           
             public_key = File.read("./id_rsa.pub")
             
            srv.vm.provision "shell", inline: <<-SCRIPT
                    mkdir -p /home/vagrant/.ssh
                    chmod 700 /home/vagrant/.ssh
                    touch /home/vagrant/.ssh/id_rsa
                    chmod 600 /home/vagrant/.ssh/id_rsa
                    echo 'Copying ansible-vm public SSH Keys to the VM'
                    echo '#{public_key}' >> /home/vagrant/.ssh/authorized_keys
                    chmod -R 600 /home/vagrant/.ssh/authorized_keys
                    echo 'Host 192.168.*.*' >> /home/vagrant/.ssh/config
                    echo 'StrictHostKeyChecking no' >> /home/vagrant/.ssh/config
                    echo 'UserKnownHostsFile /dev/null' >> /home/vagrant/.ssh/config
                    chmod -R 600 /home/vagrant/.ssh/config
                SCRIPT
            srv.vm.provision "shell", inline: $configureBox
        end
    end
    
end
