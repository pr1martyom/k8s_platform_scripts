# -- mode: ruby --
# vi: set ft=ruby :


# vagrant plugin install vagrant-disksize
# vagrant plugin update
# vagrant plugin expunge --reinstall
# vagrant plugin install vagrant-hostmanager
# vagrant plugin install vagrant-hostsupdater
# vagrant plugin install vagrant-host-shell

# Require 'yaml' module
require 'yaml'

# Read YAML file with VM details (box, CPU, RAM, IP addresses)
# Edit machines.yml to change VM configuration details
machines = YAML.load_file(File.join(File.dirname(__FILE__), 'scripts/machines.yml'))


# Inline script applies to all nodes

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

Vagrant.configure(2) do |config|

    config.vm.box = "boeboe/centos7-50gb"
    config.vm.box_version = "1.0.1"
      # Turn off default shared folders
      config.vm.synced_folder '.', '/vagrant', disabled: true
      # Turn on shared folders for kube
      config.vm.synced_folder "/tmp/kube-data", "/tmp/shared-data", mount_options: ["dmode=775,fmode=777"]
  
      machines.each do |opts|
      config.vm.define opts['box']['name'] do |config|
        config.vm.hostname = opts['box']['name'] 
        config.vm.network "public_network", bridge: "k8s-bridge", ip: opts['box']['eth1']

        config.vm.provider "virtualbox" do |v|
          v.customize ["modifyvm", :id, "--name", opts['box']['name'] ]
          v.customize ["modifyvm", :id, "--memory", opts['box']['mem'] ]
          v.customize ["modifyvm", :id, "--cpus", opts['box']['cpu'] ]
        end
  
        public_key = File.read("id_rsa.pub")
        config.vm.provision "shell", inline: <<-SCRIPT
            mkdir -p /home/vagrant/.ssh
            chmod 700 /home/vagrant/.ssh
            touch /home/vagrant/.ssh/id_rsa
            chmod 600 /home/vagrant/.ssh/id_rsa
            echo 'Copying ansible-vm public SSH Keys to the VM'
            echo '#{public_key}' >> /home/vagrant/.ssh/authorized_keys
            chmod -R 600 /home/vagrant/.ssh/authorized_keys
            echo 'Host 192.168..' >> /home/vagrant/.ssh/config
            echo 'StrictHostKeyChecking no' >> /home/vagrant/.ssh/config
            echo 'UserKnownHostsFile /dev/null' >> /home/vagrant/.ssh/config
            chmod -R 600 /home/vagrant/.ssh/config
            SCRIPT
        config.vm.provision "shell", inline: $configureBox
      end
    end
end
