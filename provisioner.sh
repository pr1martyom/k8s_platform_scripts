#!/bin/bash

# this script clones the platform scripts repository, master branch

WORKING_DIR="/home/qzhub/runner/k8s_platform_scripts"

VAGRANT_CWD="/home/qzhub/runner/k8s_platform_scripts"

REPOSITORY="git@github.com:pr1martyom/k8s_platform_scripts.git"

BRANCH="develop"

GIT=`which git`

STATUS=false

if [ "x$GIT" = "x" ];then
  echo "No git command found. install it"
  exit 1;
fi

function clone {
if [ -d "$2" ]; then 
  cd $2
  git add --all
  git commit -m "Current vagrant state `date`"
  git push 
  cd
fi
  rm -Rf $2
  mkdir -p $2
  $GIT clone -q $1 $2 -b $3
}

echo "cloning repository into ... $WORKING_DIR"
clone $REPOSITORY $WORKING_DIR $BRANCH

cd $WORKING_DIR/scripts
VM_STATUS=$(vagrant status --machine-readable | grep ",state," | egrep -o '([a-z_]*)$')

echo "Current Running machine status"
echo $VM_STATUS

# case "${VM_STATUS}" in
#   running)
#     STATUS=true
#   ;;
#   poweroff)
#      STATUS=true
#   ;;
#   *)
#      STATUS=false
#   ;;
# esac

# if [ "$STATUS" = "true" ];then
  while true; do
      read -p "Do you wish to destroy the VMs?(y/n)" yn
      case $yn in
          [Yy]* ) vagrant destroy --force; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
# fi
vagrant plugin install vagrant-vbguest
echo "Provisioning Kubernetes VMs"
vagrant up