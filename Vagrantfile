# -*- mode: ruby -*-
# vi: set ft=ruby :

# # Specify minimum Vagrant version and Vagrant API version
# Vagrant.require_version '>= 1.6.0'
VAGRANTFILE_API_VERSION = '2'

servers = [
    {
        :name => "kube-master-01",
        :type => "master",
        :box => "boeboe/centos7-50gb",
        :version => "1.0.1",        
        :eth1 => "192.168.0.3",
        :mem => "4096",
        :cpu => "2"
    },
    {
        :name => "kube-master-02",
        :type => "master",
        :box => "boeboe/centos7-50gb",
        :version => "1.0.1",        
        :eth1 => "192.168.0.4",
        :mem => "4096",
        :cpu => "2"
    },
    {
        :name => "kube-master-03",
        :type => "master",
        :box => "boeboe/centos7-50gb",
        :version => "1.0.1",        
        :eth1 => "192.168.0.5",
        :mem => "4096",
        :cpu => "2"
    },
    {
        :name => "kube-node-01",
        :type => "node",
        :box => "boeboe/centos7-50gb",
        :version => "1.0.1",
        :eth1 => "192.168.0.6",
        :mem => "8192",
        :cpu => "4"
    }
  
]



# Require 'yaml' module
# require 'yaml'

# Read YAML file with VM details (box, CPU, RAM, IP addresses)
# Edit machines.yml to change VM configuration details
# servers = YAML.load_file(File.join(File.dirname(__FILE__), ENV['SIZE']))

# # Inline script applies to all nodes

$configureBox = <<-SCRIPT
    # install python-netaddr
    yum install python-netaddr -y
    setenforce 0
    yum install sshpass -y
    yum install curl -y
    yum install net-tools -y
    yum install nc -y
    systemctl restart sshd.service
SCRIPT

# unless Vagrant.has_plugin?("vagrant-host-shell")
# 	system('vagrant plugin install vagrant-host-shell')
# 	system('vagrant plugin install vagrant-vbguest --plugin-version 0.21')
# 	raise("Plugin installed. Run command again.");
# end

# #  Inline script applies to master nodes only
# # Create and configure the VMs
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    servers.each do |server|
        config.vm.define server[:name] do |config|
            config.vm.synced_folder '.', '/vagrant', disabled: true
            config.vm.synced_folder "/shared-data/kube-data", "/shared-data", mount_options: ["dmode=775,fmode=777"]
            config.vm.box = server[:box]
            config.vm.box_version = server[:version]
            config.vm.hostname = server[:name]
            config.vm.network "public_network", bridge: "k8s-bridge", ip: server[:eth1]
            config.ssh.forward_agent = true

            config.vm.provider "virtualbox" do |config|
                config.customize ["modifyvm", :id, "--groups", "/k8s lab"]
                config.customize ["modifyvm", :id, "--memory", server[:mem]]
                config.customize ["modifyvm", :id, "--cpus", server[:cpu]]
            end
           
             public_key = File.read("./id_rsa.pub")
             
             config.vm.provision "shell", inline: <<-SCRIPT
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
            config.vm.provision "shell", inline: $configureBox
        end
    end
    
end
