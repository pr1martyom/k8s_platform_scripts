#!/bin/bash

# this script clones the platform scripts repository, master branch

WORKING_DIR="/home/qzhub/runner/k8s_platform_scripts"

VAGRANT_CWD="/home/qzhub/runner/k8s_platform_scripts"

REPOSITORY="git@github.com:pr1martyom/k8s_platform_scripts.git"

BRANCH="develop"

GIT=`which git`

STATUS=false

SIZE=""


Help()
{
   # Display Help
   echo "Vagrant VM Provisioner"
   echo
   echo "Syntax: ./provisioner.sh [S|M|L]"
   echo "options:"
   echo "S     (S)mall."
   echo "M     (M)edium."
   echo "L     (L)arge"
   echo
}
#Validate Env
validate()
{
if [ "x$GIT" = "x" ];then
  echo "No git command found. install it"
  exit 1;
fi
}
#Git clone function
function clone {
if [ -d "$2" ]; then
  cd "$2"
  $GIT pull
else
  $GIT clone -q $1 $2 -b $3
fi
}
#Configure Host Machine
function configureHost {
sudo yum install python3-pip -y 
pip3 install virtualenv --user
pip3 install pyyaml
mkdir -p /home/qzhub/.venv/kubespray 
/home/qzhub/.local/bin/virtualenv -p python3 --system-site-packages 
/home/qzhub/.venv/kubespray
source /home/qzhub/.venv/kubespray/bin/activate
pip install --upgrade pip
cd /home/qzhub/assets/kubespray
pip3 install -r requirements.txt && pip list
}
#Check ssh connectivity
function checkssh {
  if [ python sshconnect.py != 0 ]; then
   echo "Unable to ssh to one or many nodes. Please check!!" 
  exit 1; 
  fi
}

function provisionVM {
echo "Run environment validation.."  
validate

echo "cloning repository into ... $WORKING_DIR"
clone $REPOSITORY $WORKING_DIR $BRANCH


cd $WORKING_DIR/scripts
VM_STATUS=$(vagrant status --machine-readable | grep ",state," | egrep -o '([a-z_]*)$')

# if [ "$STATUS" = "true" ];then
  while true; do
      read -p "Do you wish to destroy the VMs?(y/n)" yn
      case $yn in
          [Yy]* ) cd $WORKING_DIR/scripts; vagrant destroy --force; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
# fi
echo "Provisioning Kubernetes VMs"
cd $WORKING_DIR/scripts
vagrant plugin uninstall vagrant-vbguest
vagrant plugin install vagrant-vbguest --plugin-version 0.21
vagrant up
checkssh
configureHost
}

while getopts ":SML" option; do
   case $option in
      S ) # provision small VM
        SIZE="small.yml"
         provisionVM 
         exit;;
      M ) # provision small VM
        SIZE="medium.yml"
         provisionVM 
         exit;;
      L ) # provision small VM
        SIZE="large.yml"
         provisionVM 
         exit;;
     \? ) # incorrect option
         Help
         exit;;
   esac
done
