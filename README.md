# Production Ready Kubernetes Cluster Using Vagrant

## Overview
![Kubernetes Logo](https://raw.githubusercontent.com/kubernetes-sigs/kubespray/master/docs/img/kubernetes-logo.png)

This project describes the steps required to setup a multi-node Kubernetes Cluster for Oodo Deployment.
The repository contains a Vagrantfile, [Kubespray](https://github.com/kubernetes-sigs/kubespray), a Kubernetes Implementation and bootstrap helm charts to deploy the cluster. The automation framework implemented in this project will provision a Production ready full blown multi-node Kubernets Cluster under 30 minutes with Enterprise grade monitoring capability using [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/), [Prometheus & Grafana](https://grafana.com/grafana/dashboards/315), [Kubeview](https://github.com/benc-uk/kubeview).
The implementation also includes Dynamic volume provisioning which allows storage volumes to be created on-demand. Without dynamic provisioning, cluster administrators have to manually make calls to their cloud or storage provider to create new storage volumes, and then create [PersistentVolume objects](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) to represent them in Kubernetes.The dynamic provisioning feature eliminates the need for cluster administrators to pre-provision storage. Instead, it automatically provisions storage when it is requested by users. 


## Cluster Architecture

![Scheme](logo/K8s-Dev-Architecture.png)

## Prerequisites
OS X & Linux:

- Virtualbox - https://www.virtualbox.org
- Vagrant - https://www.vagrantup.com
- Helm - https://helm.sh - v3 :)
- Ansible - https://www.ansible.com 
- Kubernetes v1.19+ - https://kubernetes.io/blog/2020/08/26/kubernetes-release-1.19-accentuate-the-paw-sitive/
- Kubespray - https://github.com/kubernetes-sigs/kubespray
- kubectl - https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/https://direnv.net
- Nginx Proxy Manager - https://nginxproxymanager.com
- Dedicated Bridge connector exists

## Quickstart

Setup a new bridge connector in the host machine. This connector establishes a bridge between host and guest Virtual Machines(s)
```ShellSession
brctl addbr k8s-bridge
ifconfig k8s-bridge 192.168.0.1 netmask 255.255.255.0
ifconfig k8s-bridge up
```
Install nfs server on the host machine.
```ShellSession
yum install nfs-utils nfs-utils-lib
systemctl enable nfs-server
systemctl start nfs-server
```
Add entry in  "/etc/exports"
```ShellSession
/kube-data *(rw,sync,fsid=0,no_root_squash,no_subtree_check,insecure)
```
Exports all shared listed in "/etc/exports:
```ShellSession
exportfs -arv
```
Allow iptables 
```ShellSession
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-port=2049/tcp
firewall-cmd --permanent --add-port=2049/udp
firewall-cmd --reload
```

Deploy nfs provisioner via helm chart.
Dynamic NFS Provisioning: is allows storage volumes to be created on-demand. The dynamic provisioning feature eliminates the need for cluster administrators to code-provision storage. Instead, it automatically provisions storage when it is requested by users. Persistent volumes are provisioned as ${namespace}-${pvcName}-${pvName}.
You will need a operational Kubernetes Cluster.
To deploy a NFS provisioner into the cluster you can run [provisioner.sh](provisioner.sh) script to deploy the nfs-provisioner helm chart.

To deploy a multi-node Kubernetes Deployment run the following steps:
Update [machines.yml](scripts/machines.yml) which describes the target node structure
```ShellSession
---
- box:
    name: "kube-master-01"
    type: "master"
    img: "boeboe/centos7-50gb"
    version: "1.0.1"
    eth1: "192.168.0.3"
    mem: "4096"
    cpu: "2"
- box:
    name: "kube-master-02"
    type: "master"
    img: "boeboe/centos7-50gb"
    version: "1.0.1"
    eth1: "192.168.0.4"
    mem: "4096"
    cpu: "2"
- box:
    name: "kube-master-03"
    type: "master"
    img: "boeboe/centos7-50gb"
    version: "1.0.1"
    eth1: "192.168.0.5"
    mem: "4096"
    cpu: "2"
....   
```
Run [provisioner.sh](provisioner.sh) scripts to deploy and bootstrap the cluster. [provisioner.sh](provisioner.sh) is a comprehensive self-service script used to build the Vagrant nodes, install Kubespray - https://github.com/kubernetes-sigs/kubespray  Kubernetes and helm charts.

Note: Option (A) shown below will deploy a Full blown Kubernetes Cluster and integrated ingress controller, Cluster monitoring and NFS storage provisioners under 30 minute(s).


# Step 1: create dir runner

mkdir runner

# Step 2: git clone
  
cd runner
  
git clone https://github.com/pr1martyom/k8s_platform_scripts/
 
git checkout develop
  
# Step 3: Copy id_rsa.pub
  
ssh-keygen

cd /home/qzhub/runner/k8s_platform_scripts/

cat ~/.ssh/id_rsa.pub > id_rsa.pub

# Step 4: Create VMs
  
./provisioner.sh -P
 
# Step 5: Install k8s

./provisioner.sh -I

cp /tmp/config ~/.kube/

# Step 6: Check K8s

kubectl get node

# Step 7: Deoloy K8s Bootstrap Charts

./provisioner.sh -D

```ShellSession

[qzhub@qzhub-dev-01 k8s_platform_scripts]$ ./provisioner.sh 
Vagrant VM Provisioner

Syntax: ./provisioner.sh -[P|I|D|A|O]
Example: ./provisioner.sh -P
options:
P     (P)Provision VM(s).
I     (I)Install K8s.
D     (D)Deploy K8s Bootstrap Charts 
A     (A)Provision VM(s), Install K8s and Deploy Bootstrap Charts
O     (O)Deploy Oodo

....   
```

## Platform End-points
- [Password protected Kubernetes Dashboard] (https://k8s.qzhub.kz/)
- [Password protected Prometheus & Grafana Monitoring] (https://grafana.qzhub.kz && https://prometheus.qzhub.kz)
- [Password protected Kubernetes Structure View] (https://kubeview.qzhub.kz/)
- [A smoketest utility shows Cluster health, configurations & versions] (https://smoketest.qzhub.kz/)

## Dynamic Storage

Dynamic storage provisioners are enabled using [NFS Path Provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner), provides a way for the Kubernetes users to utilize the NFS  storage in each node. Based on the user configuration, the NFS  Path Provisioner will create `hostPath` based persistent volume on the node automatically. It utilizes the features introduced by Kubernetes [NFS Persistent Volume feature](https://kubernetes.io/docs/concepts/storage/storage-classes/), but make it a simpler solution than the built-in `NFS` volume feature in Kubernetes.

A Kubernetes [Storage-Class](https://kubernetes.io/docs/concepts/storage/storage-classes/) "kube-nfs" will be created automatically to factilitate Dynamic NFS storage provisioning.

Dunamic storage provisioners simplifies the deployment and management of storage provisioning for StatefulSet deployments such as Postgres and Oodo Deployments.

Prometheus & Grafana monitoring is enabled as Statefulset deployment as show below.

```ShellSession
[qzhub@qzhub-dev-01 ~]$ kubectl get pods -n nfs-provisioner
NAME                                  READY   STATUS    RESTARTS   AGE
nfs-pod-provisioner-c789dfb8d-vvkbs   1/1     Running   0          11h
[qzhub@qzhub-dev-01 ~]$ 

vagrant@kube-node-01 kube-data]$ pwd
/kube-data
[vagrant@kube-node-01 kube-data]$ ls -altr
total 12
dr-xr-xr-x. 21 root root  287 Apr  6 14:02 ..
drwxrwxrwx.  4 root root 4096 Apr  7 01:40 postgres-data-postgres-postgresql-0-pvc-6414a513-f241-47e4-bb31-947ca7d6c434
drwxrwxrwx.  4 root root 4096 Apr  7 03:21 .
drwxrwxrwx.  3 root root 4096 Apr  7 03:21 monitoring-prometheus-monitoring-kube-prometheus-prometheus-db-prometheus-monitoring-kube-prometheus-prometheus-0-pvc-f4aae4ee-9685-47a9-8657-fdc3a7762cee
[vagrant@kube-node-01 kube-data]$ 
```

## Oodo Deployment
Odoo is a suite of web-based open source business apps. The main Odoo Apps include an Open Source CRM, Website Builder, eCommerce, Project Management, Billing & Accounting, Point of Sale, Human Resources, Marketing, Manufacturing, Purchase Management etc.
Oodo application can be deployed using the [Oodo Bitnami Helm Chart](https://bitnami.com/stack/odoo/helm)
Choose option -O in the [provisioner.sh](provisioner.sh) automation script to deploy Oodo Application.
Oodo charts have been optimized for Production Deployment. 

```ShellSession
[qzhub@qzhub-dev-01 k8s_platform_scripts]$ ./provisioner.sh 
Vagrant VM Provisioner

Syntax: ./provisioner.sh -[P|I|D|A|O]
Example: ./provisioner.sh -P
options:
P     (P)Provision VM(s).
I     (I)Install K8s.
D     (D)Deploy K8s Bootstrap Charts 
A     (A)Provision VM(s), Install K8s and Deploy Bootstrap Charts
O     (O)Deploy Oodo

....   
```
Oodo will utilize the custom NFS Dynamic storage provisioner as below.

```ShellSession
[qzhub@qzhub-dev-01 k8s_platform_scripts]$ kubectl get sc
NAME               PROVISIONER   RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-storageclass   kube-nfs      Delete          Immediate           false                  14h
```

List Oodo related Persistent Volume and Persistent Volume Claims

```ShellSession
[qzhub@qzhub-dev-01 k8s_platform_scripts]$ kubectl get pv 
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                                                                               STORAGECLASS       REASON   AGE
pvc-57fe8fea-16f8-4ff5-8c86-2c498d851b3f   300Gi      RWO            Delete           Bound    oodo/oodo-odoo                                                                                                      nfs-storageclass            10m
pvc-7b0b760d-798c-4e32-9e88-96b2ca40fd2a   300Gi      RWO            Delete           Bound    oodo/data-oodo-postgresql-0                                                                                         nfs-storageclass            10m

[qzhub@qzhub-dev-01 k8s_platform_scripts]$ kubectl get pvc -n oodo
NAME                     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
data-oodo-postgresql-0   Bound    pvc-7b0b760d-798c-4e32-9e88-96b2ca40fd2a   300Gi      RWO            nfs-storageclass   10m
oodo-odoo                Bound    pvc-57fe8fea-16f8-4ff5-8c86-2c498d851b3f   300Gi      RWO            nfs-storageclass   10m

```
## Enable Single-Sign-On Using Keycloak
OAuth is an authorization framework that enables applications to obtain limited access to user accounts on an HTTP service. It works by delegating user authentication to the service that hosts the user account, and authorizing third-party applications to access the user account.

In our scenario Keycloak acts as the OAuth service and Odoo as the application that delegates the user authentication. In this guide you learn how to configure Odoo and Keycloak to handle an implicit OAuth flow

![image](https://user-images.githubusercontent.com/81404769/117096709-3d0ad680-adad-11eb-9bda-67ac675c280d.png)

This image depicts what we want to achieve. The user accesses Odoo and then decides to authenticate with Keycloak. He gets forwarded to the login page and authorizes the Odoo application to access his account informations. He then gets redirected back to the application. Trust is enabled by only allowing selected applications to be redirected. If you want to know more about OAuth authentication head down to the source chapter.

We assume that we have the following service up and running:
Keycloak Auth Server: https://keycloak.qzhub.kz/auth/
Odoo Application: https://odoo.qzhub.kz/web/login

## Setup Keycloak client
Open the Keycloak management console,
![image](https://user-images.githubusercontent.com/81404769/117443858-0c2ccc00-af7c-11eb-984f-9698687d0578.png)

Create a new realm oodo
![image](https://user-images.githubusercontent.com/81404769/117443968-2d8db800-af7c-11eb-9fd3-bf73fbd149a3.png)

select your realm odoo, navigate to Configure > Clients and create a new client. 

For Client ID use odoo, for Client Protocol openid-connect and as Root URL enter ${authBaseUrl}. Click save.

![image](https://user-images.githubusercontent.com/81404769/117444124-6037b080-af7c-11eb-97fb-609906d0d273.png)

![image](https://user-images.githubusercontent.com/81404769/117444459-d63c1780-af7c-11eb-9067-7c11415a6fd9.png)


In the client edit view make the following configurations.

Access type: confidential

Odoo OAuth will pass a secret to intiate the login protocol.

Implicit Flow Enabled: On

Odoo OAuth requires the implicit flow.

Valid Redirect URIs:

https://odoo.qzhub.kz/auth_oauth/signin
*

Base URL:

Leave the Base URL, Admin URL and Web Origins empty.


Save the settings and open the Client Scopes tab.
![image](https://user-images.githubusercontent.com/81404769/117446479-7a26c280-af7f-11eb-8ac6-350e0b7e5f26.png)

Save the settings and open the Mappers tab.

![image](https://user-images.githubusercontent.com/81404769/117446593-9fb3cc00-af7f-11eb-90a4-bef3f89e0806.png)

Click on Add Builtin. Select and add the email entry. Open the email mapper and set as Token Claim Name the value user_id.

This will ensure that the token has the email address set as user id.



##Nginx Manager Setup for Keycloak

Nginx Manager Proxy Host settings must have specific headers as custom configurations to handle the mixed content forwarded from Nginx Manager to the KeyCloak Admin Console inside a typical setup where keycloak is behind the Nginx Manager.

#How to configure Nginx Manager Proxy Host  for Keycloak?

![image](https://user-images.githubusercontent.com/81404769/117774057-6e3b4900-b27c-11eb-8b2f-22174e7d5ab9.png)

Custom Confiuration settings
![image](https://user-images.githubusercontent.com/81404769/117774119-801cec00-b27c-11eb-9832-e1b3e737e874.png)

Standard SSL Settings
![image](https://user-images.githubusercontent.com/81404769/117774188-9165f880-b27c-11eb-9a0b-a7a965270c99.png)

##Pass proxyAddressForwarding for Keycloak Helm Install

```
helm upgrade --install keycloak --namespace keycloak --set proxyAddressForwarding=true .
```
Note: 
   proxyAddressForwarding option is already included in [provisioner.sh](provisioner.sh) script

## Ingress Controller Settings.
   Apply below settings in the ingress controller

```
  forwarded-for-header: X-Client-IP
  generate-request-id: "true"
  use-forwarded-headers: "true"
```


 sample Ingress Controller ConfigMap
 
 ```
 # Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  forwarded-for-header: X-Client-IP
  generate-request-id: "true"
  use-forwarded-headers: "true"
kind: ConfigMap
metadata:
  annotations:
    meta.helm.sh/release-name: ingress-controller
    meta.helm.sh/release-namespace: ingress-controller
  creationTimestamp: "2021-04-21T01:52:07Z"
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-controller
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/version: 0.45.0
    helm.sh/chart: ingress-nginx-3.29.0
  name: ingress-controller-ingress-nginx-controller
  namespace: ingress-controller
  resourceVersion: "6984487"
  selfLink: /api/v1/namespaces/ingress-controller/configmaps/ingress-controller-ingress-nginx-controller
  uid: 8758838f-1129-4623-85e6-039de70f75b1
```


## Supported Linux Distributions
- **CentOS/RHEL** 7, 8 (experimental: see [centos 8 notes](docs/centos8.md))
Note: The list of validated [docker versions](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker) is 1.13.1, 17.03, 17.06, 17.09, 18.06, 18.09 and 19.03. The recommended docker version is 19.03. The kubelet might break on docker's non-standard version numbering (it no longer uses semantic versioning). To ensure auto-updates don't break your cluster look into e.g. yum versionlock plugin or apt pin).

## Author
Created by Rajesh Ramasamy (rajinovat@gmail.com).

Copyright 2021, Cloud Native Solutions Pvt.Ltd  Distributed under Apache License Version 2.0 ,see LICENSE for details.

##  Disclaimer: 

Copyright (c) 2021  Cloud Native Solutions Pvt.Ltd Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.
* None of the names of its contributors may be used to endorse
or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
