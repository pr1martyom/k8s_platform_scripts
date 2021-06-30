# k8s_platform_scripts
K8s Platform Scripts

1. Install Vbox and Vagrant

# Step 1: Refresh Software Repositories

sudo yum update

# Step 2: Install VirtualBox

sudo yum install epel-release -y

sudo yum install gcc dkms make qt libgomp patch -y

sudo yum install kernel-headers kernel-devel binutils glibc-headers glibc-devel font-forge -y

sudo wget http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo -P /etc/yum.repos.d 

sudo yum install VirtualBox-6.1 -y


# Step 3: Install Vagrant on CentOS

wget https://releases.hashicorp.com/vagrant/2.2.15/vagrant_2.2.15_x86_64.rpm

sudo yum  install vagrant_2.2.15_x86_64.rpm -y


# Step 4: Install helm

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Step 5: Install docker and docker-compose

sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

sudo yum install -y yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install docker-ce docker-ce-cli containerd.io -y

sudo systemctl start docker

sudo systemctl enable docker

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


# Step 6: Install pip

sudo yum -y install python-pip

sudo yum -y install python3

sudo yum install python-devel -y

sudo yum groupinstall 'development tools' -y

# Step 6: Install git

sudo yum install git -y

# Step 7: Install nginx proxy manager

mkdir npm && cd npm

docker-compose up -d

# Step 8: add ip to /etc/hosts


# Step 9: Clone repository

git clone https://github.com/pr1martyom/k8s_platform_scripts

cd k8s_platform_scripts/

git checkout develop
