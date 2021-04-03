#!/bin/bash

# this script clones the platform scripts repository, master branch

TIME="$(date +%s)"

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
   echo "Syntax: ./provisioner.sh -[P|I|D|A]"
   echo "Example: ./provisioner.sh -P"
   echo "options:"
   echo "P     (P)Provision VM(s)."
   echo "I     (I)Install K8s."
   echo "D     (D)Deploy K8s Bootstrap Charts "
   echo "A     (A)Provision VM(s), Install K8s and Deploy Charts"
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
cd $RUNNER_DIR; 
ansible-playbook -i /home/qzhub/runner/k8s_platform_scripts/scripts/inventory/qzhub/hosts.ini ./cluster.yml -become --become-user=root -i  /home/qzhub/.ssh/id_rsa -e ansible_user=vagrant
ssh vagrant@kube-master-01 "sudo cat /root/.kube/config" > /tmp/config
echo "K8s Install Completed..." 
}


function installCharts {
echo "Deploying K8s Bootstrap Helm Charts(s)"    
export KUBECONFIG=/tmp/config
#Install ingress-controller
echo "Installing Ingress Controller.."
cd $RUNNER_DIR/charts/nginx-ingress
helm upgrade --debug --install --create-namespace ingress-controller -n ingress-controller --set controller.name=nginx-ingress-controller  --set controller.kind=daemonset --set controller.healthStatus=true --set controller.healthStatusURI="/healthz" --set controller.ingressClass=nginx-controller  --set controller.service.type=NodePort --set controller.service.httpPort.nodePort=32038 --set controller.service.httpsPort.nodePort=32034 --set prometheus.create=true --set controller.service.customPorts[0].port=9113 --set controller.service.customPorts[0].targetPort=9113 --set controller.service.customPorts[0].protocol=TCP --set controller.service.customPorts[0].name=ingress-prometheus --set controller.service.customPorts[0].nodePort=31040 --set-string controller.config.entries.use-forward-headers=true,controller.config.entries.compute-full-forwarded-for=true,controller.config.entries.use-proxy-protocol=true .


echo "Installing local storage provisioner"
cd $RUNNER_DIR/charts/local-provisioner
kubectl apply -f local-path-storage.yaml
echo "Install Charts Completed..." 


echo "Installing Smoketest.."
cd $RUNNER_DIR/charts/helm-smoketest
helm upgrade --debug --install --create-namespace smoketest -n smoketest --set image.repository=sohnaeo/nginx-php-http-header --set image.tag=1.11 --set ingressexternalClass.name=nginx-controller --set ingress.external.hosts[0]=smoketest.qzhub.kz  --set kubernetes.version=1.19.7 --set kubernetes.nginxingressVersion=1.19.6 --set kubernetes.etcdVersion=3.4.13 --set kubernetes.calicoVersion=3.16.5 --set kubernetes.dockerVersion=1.13.1 --set kubernetes.helmVersion=3.3.4 .


echo "Installing Kubeview.."
cd $RUNNER_DIR/charts/kubeview 
helm upgrade --debug --install --create-namespace kubeview -n kubeview --set ingress.hosts[0].host=kubeview.qzhub.kz --set image.tag=0.1.18 --set-string ingress.hosts[0].paths[0]="/" --set ingress.className=nginx-controller .


echo "Installing Kubernetes dashboard.."
cd $RUNNER_DIR/charts/k8s-dashboard
helm upgrade --install k8s-dashboard .


echo "Installing Prometheus/Grafna.."
cd $RUNNER_DIR/charts/kube-prometheus-stack
helm upgrade --debug --install --create-namespace monitoring -n monitoring .

TIME="$(($(date +%s)-TIME))"
echo "It took ${TIME} seconds!"

}

function checkssh {
result=`python $RUNNER_DIR/scripts/tools.py "${RUNNER_DIR}${SIZE}"`
  if  [ "$result" != "0" ]; then
   echo "Unable to ssh to one or many nodes. Please check!!" 
   exit 1; 
  fi
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

while getopts ":PIDA" option; do
   case $option in
      P ) # provision small VM
         SIZE="/scripts/large.yml"
         provisionVM 
         exit;;
      I ) # provision small VM
         SIZE="/scripts/large.yml"
         launchK8sInstall
         exit;;
      D ) # provision small VM
         installCharts
         exit;;
      A ) # provision small VM
         SIZE="/scripts/large.yml"
         provisionVM
         launchK8sInstall
         installCharts
         exit;;
      \? ) echo "Invalid option -${option}" >&2
          usage && exit 1
      ;;
   esac
done
