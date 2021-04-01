#!/bin/bash

# this script clones the platform scripts repository, master branch

WORKING_DIR="/home/qzhub/runner/k8s_platform_scripts"

VAGRANT_CWD="/home/qzhub/runner/k8s_platform_scripts"

REPOSITORY="git@github.com:pr1martyom/k8s_platform_scripts.git"

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
function configureHost {
#sudo yum install python3-pip -y 
pip3 install virtualenv --user
mkdir -p /home/qzhub/.venv/kubespray 
/home/qzhub/.local/bin/virtualenv -p python3 --system-site-packages 
/home/qzhub/.venv/kubespray
source /home/qzhub/.venv/kubespray/bin/activate
pip install --upgrade pip
cd /home/qzhub/assets/kubespray
pip3 install -r requirements.txt && pip list
}

function checkssh {
result=`python $WORKING_DIR/scripts/tools.py "${WORKING_DIR}${SIZE}"`

  if  [ "$result" != "0" ]; then
   echo "Unable to ssh to one or many nodes. Please check!!" 
   exit 1; 
  fi
}

function provisionVM {

echo "cloning repository into ... $WORKING_DIR"
clone $REPOSITORY $WORKING_DIR $BRANCH

cd $WORKING_DIR; vagrant destroy --force;

# fi
echo "Provisioning Kubernetes VMs"
cd $WORKING_DIR
vagrant plugin uninstall vagrant-vbguest
vagrant plugin install vagrant-vbguest --plugin-version 0.21
export SIZE="$SIZE"
cd $WORKING_DIR; vagrant up
echo "Check SSH Connectivity....."
checkssh
configureHost
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