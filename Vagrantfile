# -- mode: ruby --
# vi: set ft=ruby :


# vagrant plugin install vagrant-disksize
# vagrant plugin update
# vagrant plugin expunge --reinstall
# vagrant plugin install vagrant-hostmanager
# vagrant plugin install vagrant-hostsupdater
# vagrant plugin install vagrant-host-shell


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
    },
    {
        :name => "kube-node-02",
        :type => "node",
        :box => "boeboe/centos7-50gb",
        :version => "1.0.1",
        :eth1 => "192.168.0.7",
        :mem => "8192",
        :cpu => "4"
    },
    {
        :name => "kube-node-03",
        :type => "node",
        :box => "boeboe/centos7-50gb",
        :version => "1.0.1",
        :eth1 => "192.168.0.8",
        :mem => "8192",
        :cpu => "4"
    },
    {
        :name => "kube-node-04",
        :type => "node",
        :box => "boeboe/centos7-50gb",
        :version => "1.0.1",
        :eth1 => "192.168.0.9",
        :mem => "8192",
        :cpu => "4"
    },
    {
        :name => "kube-node-05",
        :type => "node",
        :box => "boeboe/centos7-50gb",
        :version => "1.0.1",
        :eth1 => "192.168.0.10",
        :mem => "8192",
        :cpu => "4"
    }
]


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


#  Inline script applies to master nodes only

Vagrant.configure("2") do |config|
    config.vagrant.plugins = "vagrant-host-shell"
    config.vagrant.plugins = "trigger"
    servers.each do |opts|
        config.vm.define opts[:name] do |config|
        config.vm.synced_folder '.', '/vagrant', disabled: true
            config.vm.box = opts[:box]
            config.vm.box_version = opts[:version]
            config.vm.hostname = opts[:name]
            config.vm.network "public_network", bridge: "k8s-bridge", ip: opts[:eth1]
            config.ssh.forward_agent = true

            config.vm.provider "virtualbox" do |v|
                v.name = opts[:name]
                v.customize ["modifyvm", :id, "--groups", "/k8s lab"]
                v.customize ["modifyvm", :id, "--memory", opts[:mem]]
                v.customize ["modifyvm", :id, "--cpus", opts[:cpu]]
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