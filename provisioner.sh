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
   echo "Syntax: ./provisioner.sh -[P|I|A]"
   echo "Example: ./provisioner.sh -P"
   echo "options:"
   echo "P     (P)Provision VM(s) and Install K8(s)."
   echo "I     (I)Install Charts."
   echo "A     (A)Provision VM(s) and Install Charts"
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
cd $RUNNER_DIR; 
#sudo yum install python3-pip -y 
pip3 install virtualenv --user
mkdir -p /home/qzhub/.venv
/home/qzhub/.local/bin/virtualenv -p python3 --system-site-packages /home/qzhub/.venv
source /home/qzhub/.venv/bin/activate
pip install --upgrade pip
pip3 install -r requirements.txt && pip list
ansible-playbook -i /home/qzhub/runner/k8s_platform_scripts/scripts/inventory/qzhub/hosts.ini ./cluster.yml -become --become-user=root -i  /home/qzhub/.ssh/id_rsa -e ansible_user=vagrant
ssh vagrant@kube-master-01 "sudo cat /root/.kube/config" > /tmp/config
}


function installCharts {
export KUBECONFIG=/tmp/config
#Install ingress-controller
echo "Installing Ingress Controller.."
cd $RUNNER_DIR/charts/nginx-ingress
helm upgrade --debug --install --create-namespace ingress-controller -n ingress-controller --set controller.name=nginx-ingress-controller  --set controller.kind=daemonset --set controller.healthStatus=true --set controller.healthStatusURI="/healthz" --set controller.ingressClass=nginx-controller  --set controller.service.type=NodePort --set controller.service.httpPort.nodePort=32038 --set controller.service.httpsPort.nodePort=32034 --set prometheus.create=true --set controller.service.customPorts[0].port=9113 --set controller.service.customPorts[0].targetPort=9113 --set controller.service.customPorts[0].protocol=TCP --set controller.service.customPorts[0].name=ingress-prometheus --set controller.service.customPorts[0].nodePort=31040 --set-string controller.config.entries.use-forward-headers=true,controller.config.entries.compute-full-forwarded-for=true,controller.config.entries.use-proxy-protocol=true .

echo "Installing Smoketest.."
cd $RUNNER_DIR/charts/helm-smoketest
helm upgrade --debug --install --create-namespace smoketest -n smoketest --set image.repository=sohnaeo/nginx-php-http-header --set image.tag=1.11 --set ingressexternalClass.name=nginx-controller --set ingress.external.hosts[0]=smoketest.qzhub.kz  --set kubernetes.version=1.19.7 --set kubernetes.nginxingressVersion=1.19.6 --set kubernetes.etcdVersion=3.4.13 --set kubernetes.calicoVersion=3.16.5 --set kubernetes.dockerVersion=1.13.1 --set kubernetes.helmVersion=3.3.4 .

echo "Installing Kubeview.."
cd $RUNNER_DIR/charts/kubeview 
helm upgrade --debug --install --create-namespace kubeview -n kubeview --set ingress.hosts[0].host=kubeview.qzhub.kz --set-string ingress.hosts[0].paths[0]="/" --set ingress.className=nginx-controller .

echo "Installing Kubernetes dashboard.."
cd $RUNNER_DIR/charts/k8s-dashboard
kubectl apply -f $RUNNER_DIR/charts/k8s-dashboard/recommended.yaml
kubectl apply -f $RUNNER_DIR/charts/k8s-dashboard/k8s-dashboard-ing.yaml

echo "Installing Prometheus/Grafna.."
cd $RUNNER_DIR/charts/kube-prometheus-stack
helm upgrade --debug --install --create-namespace monitoring -n monitoring .


echo "Installing local storage provisioner"
cd $RUNNER_DIR/charts/local-provisioner
kubectl apply -f local-path-storage.yaml

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
cd $RUNNER_DIR; vagrant destroy --force; vagrant plugin install vagrant-vbguest --plugin-version 0.21; vagrant up
echo "Check SSH Connectivity....."
checkssh
launchK8sInstall
}

if [[ ! $@ =~ ^\-.+ ]]
then
  usage
fi

while getopts ":PIA" option; do
   case $option in
      P ) # provision small VM
         SIZE="/scripts/large.yml"
         provisionVM 
         exit;;
      I ) # provision small VM
         SIZE="/scripts/large.yml"
         installCharts
         exit;;
      A ) # provision small VM
         SIZE="/scripts/large.yml"
         provisionVM
         installCharts
         exit;;
      \? ) echo "Invalid option -${option}" >&2
          usage && exit 1
      ;;
   esac
done