#!/bin/bash

# this script clones the platform scripts repository, master branch

RUNNER_DIR="/home/qzhub/runner/k8s_platform_scripts"

VAGRANT_CWD="/home/qzhub/runner/k8s_platform_scripts"

REPOSITORY="git@github.com:pr1martyom/k8s_platform_scripts.git"

WORKSPACE_DIR="/home/qzhub/workspace/k8s_platform_scripts"

BRANCH="develop"

GIT=`which git`

STATUS=false

SIZE=""


usage()
{
   # Display Help
   echo "Vagrant VM Provisioner"
   echo
   echo "Syntax: ./provisioner.sh -[S|M|L]"
   echo "Example: ./provisioner.sh -S"
   echo "options:"
   echo "S     (S)mall."
   echo "M     (M)edium."
   echo "L     (L)arge"
   echo
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
function launchK8sInstall {
cd $WORKSPACE_DIR; 
#sudo yum install python3-pip -y 
pip3 install virtualenv --user
mkdir -p /home/qzhub/.venv
yes | cp -rpf ./kubernetes/kubespray /home/qzhub/.venv
/home/qzhub/.local/bin/virtualenv -p python3 --system-site-packages /home/qzhub/.venv
source /home/qzhub/.venv/bin/activate
pip install --upgrade pip
cd /home/qzhub/.venv/kubespray
pip3 install -r requirements.txt && pip list
ansible-playbook -i /home/qzhub/runner/k8s_platform_scripts/scripts/inventory/qzhub/hosts.ini ./cluster.yml -become --become-user=root -i / /home/qzhub/.ssh/id_rsa -e ansible_user=vagrant

}

function checkssh {
result=`python $RUNNER_DIR/scripts/tools.py "${RUNNER_DIR}${SIZE}"`
  if  [ "$result" != "0" ]; then
   echo "Unable to ssh to one or many nodes. Please check!!" 
   exit 1; 
  fi
}

function provisionVM {
echo "cloning repository into ... $RUNNER_DIR"
clone $REPOSITORY $RUNNER_DIR $BRANCH
echo "Provisioning Kubernetes VMs"
#d $RUNNER_DIR; vagrant destroy --force; vagrant plugin install vagrant-vbguest --plugin-version 0.21; vagrant up
echo "Check SSH Connectivity....."
checkssh
launchK8sInstall
}

if [[ ! $@ =~ ^\-.+ ]]
then
  usage
fi

while getopts ":SML" option; do
   case $option in
      S ) # provision small VM
        SIZE="/scripts/small.yml"
         provisionVM 
         exit;;
      M ) # provision small VM
        SIZE="/scripts/medium.yml"
         provisionVM 
         exit;;
      L ) # provision small VM
        SIZE="/scripts/large.yml"
         provisionVM 
         exit;;
      \? ) echo "Invalid option -${option}" >&2
          usage && exit 1
      ;;
   esac
done