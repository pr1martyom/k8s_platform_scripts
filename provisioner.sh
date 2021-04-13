#!/bin/bash

# this script clones the platform scripts repository, master branch

TIME="$(date +%s)"

RUNNER_DIR="/home/qzhub/runner/k8s_platform_scripts"

VAGRANT_CWD="/home/qzhub/runner/k8s_platform_scripts"

REPOSITORY="git@github.com:pr1martyom/k8s_platform_scripts.git"

BRANCH="develop"

GIT=`which git`

STATUS=false

SIZE=""

DOMAIN=""

usage()
{
   # Display Help
   echo "Vagrant VM Provisioner"
   echo
   echo "Syntax: ./provisioner.sh -[P|I|D|A|O]"
   echo "Example: ./provisioner.sh -P"
   echo "options:"
   echo "P     (P)Provision VM(s)."
   echo "C     (C)Check SSH Connectivity."
   echo "I     (I)Install K8s."
   echo "D     (D)Deploy K8s Bootstrap Charts "
   echo "A     (A)Provision VM(s), Install K8s and Deploy Bootstrap Charts"
   echo "O     (O)Deploy Oodo"
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
echo "Starting K8s Install..."    
#sudo yum install python3-pip -y 
pip3 install virtualenv --user
mkdir -p /home/qzhub/.venv
/home/qzhub/.local/bin/virtualenv -p python3 --system-site-packages /home/qzhub/.venv
source /home/qzhub/.venv/bin/activate
pip install --upgrade pip
cd $RUNNER_DIR/kubernetes/kubespray/
pip3 install -r requirements.txt && pip list
ansible-playbook -i /home/qzhub/runner/k8s_platform_scripts/scripts/inventory/qzhub/hosts.ini ./cluster.yml -become --become-user=root -i  /home/qzhub/.ssh/id_rsa -e ansible_user=vagrant
ssh vagrant@kube-master-01 "sudo cat /root/.kube/config" > /tmp/config
echo "K8s Install Completed..." 
}


function installBootCharts {
echo "Deploying K8s Bootstrap Helm Charts(s)"    
export KUBECONFIG=/tmp/config
#Install ingress-controller
echo "Installing Ingress Controller.."
cd $RUNNER_DIR/charts/nginx-ingress
$helm upgrade --debug --install --create-namespace ingress-controller -n ingress-controller --set controller.name=nginx-ingress-controller  --set controller.kind=daemonset --set controller.healthStatus=true --set controller.healthStatusURI="/healthz" --set controller.ingressClass=nginx-controller  --set controller.service.type=NodePort --set controller.service.httpPort.nodePort=32038 --set controller.service.httpsPort.nodePort=32034 --set prometheus.create=true --set controller.service.customPorts[0].port=9113 --set controller.service.customPorts[0].targetPort=9113 --set controller.service.customPorts[0].protocol=TCP --set controller.service.customPorts[0].name=ingress-prometheus --set controller.service.customPorts[0].nodePort=31040 --set-string controller.config.entries.use-forward-headers=true,controller.config.entries.compute-full-forwarded-for=true,controller.config.entries.use-proxy-protocol=true .


echo "Installing nfs storage provisioner"
cd $RUNNER_DIR/charts/nfs-provisioner
kubectl create namespace nfs-provisioner
kubectl apply -f $RUNNER_DIR/charts/nfs-provisioner/nfs-service-account-role-bindings.yaml
kubectl apply -f $RUNNER_DIR/charts/nfs-provisioner/nfs-autoprovisioner.yaml
kubectl apply -f $RUNNER_DIR/charts/nfs-provisioner/storage-class.yaml

echo "Installing Smoketest.."
cd $RUNNER_DIR/charts/helm-smoketest
helm upgrade --debug --install --create-namespace smoketest -n smoketest --set image.repository=sohnaeo/nginx-php-http-header --set image.tag=1.11 --set ingressexternalClass.name=nginx-controller --set ingress.external.hosts[0]=smoketest.${DOMAIN}  --set kubernetes.version=1.19.7 --set kubernetes.nginxingressVersion=1.19.6 --set kubernetes.etcdVersion=3.4.13 --set kubernetes.calicoVersion=3.16.5 --set kubernetes.dockerVersion=1.13.1 --set kubernetes.helmVersion=3.3.4 .


echo "Installing Kubeview.."
cd $RUNNER_DIR/charts/kubeview 
helm upgrade --debug --install --create-namespace kubeview -n kubeview --set ingress.hosts[0].host=kubeview.${DOMAIN} --set image.tag=0.1.18 --set-string ingress.hosts[0].paths[0]="/" --set ingress.className=nginx-controller .


echo "Installing Kubernetes dashboard.."
cd $RUNNER_DIR/charts/k8s-dashboard
helm upgrade --install k8s-dashboard -set ingress.hosts[0].host=k8s.${DOMAIN} .


echo "Installing Prometheus/Grafna.."
cd $RUNNER_DIR/charts/kube-prometheus-stack
helm upgrade --debug --install --create-namespace monitoring -n monitoring --set grafana.ingress.hosts[0]=grafana.$DOMAIN --set prometheus.ingress.hosts[0]=prometheus.$DOMAIN --set alertmanager.ingress.hosts[0]=alertmanager.$DOMAIN .

TIME="$(($(date +%s)-TIME))"
echo "It took ${TIME} seconds!"

}


function installOodoChart {
echo "Deploying Oodo Helm Chart(s)"    
export KUBECONFIG=/tmp/config

cd $RUNNER_DIR/charts/odoo
echo  $RUNNER_DIR/charts/odoo

echo "Installing Oodo Helm Chart.."

kubectl create ns oodo
helm upgrade --install oodo -n oodo --set ingress.hostname=oodo.$DOMAIN .
}



function checkssh {
result=`python $RUNNER_DIR/scripts/tools.py "${RUNNER_DIR}${SIZE}"`
  if  [ "$result" != "0" ]; then
   echo "Unable to ssh to one or many nodes. Please check!!" 
   exit 1; 
  fi
 echo "SSH Connectivity successfull on all nodes" 
}

function domain {
echo "Enter domain name?"
read domain
DOMAIN=${domain}
}

function provisionVM {
echo "Provisioning VM(s)"  
echo "cloning repository into ... $RUNNER_DIR"
clone $REPOSITORY $RUNNER_DIR $BRANCH
echo "Provisioning Kubernetes VMs"
cd $RUNNER_DIR; vagrant destroy --force; vagrant plugin install vagrant-vbguest --plugin-version 0.21; vagrant up
echo "Check SSH Connectivity....."
checkssh
}

if [[ ! $@ =~ ^\-.+ ]]
then
  usage
fi

while getopts ":CPIDAO" option; do
   case $option in
      P ) # provision VM
         SIZE="/scripts/machines.yml"
         provisionVM 
         exit;;
      C ) # Check SSH connectivity
         SIZE="/scripts/machines.yml"
         checkssh
         exit;;
      I ) #  Install K8s
         SIZE="/scripts/machines.yml"
         launchK8sInstall
         exit;;
      D ) # Install bootstrap helm charts
         domain
         installBootCharts
         exit;;
      O ) # Install oodo
         domain
         installOodoChart
         exit;;
      A ) #  perform all tasks
         SIZE="/scripts/machines.yml"
         domain
         provisionVM
         launchK8sInstall
         installBootCharts
         exit;;
      \? ) echo "Invalid option -${option}" >&2
          usage && exit 1
      ;;
   esac
done


