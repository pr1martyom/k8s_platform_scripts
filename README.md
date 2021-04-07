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

```ShellSession

[qzhub@qzhub-dev-01 k8s_platform_scripts]$ ./provisioner.sh 
Vagrant VM Provisioner

Syntax: ./provisioner.sh -[P|I|D|A]
Example: ./provisioner.sh -P
options:
P     (P)Provision VM(s).
I     (I)Install K8s.
D     (D)Deploy K8s Bootstrap Charts 
A     (A)Provision VM(s), Install K8s and Deploy Charts

....   
```

## Platform End-points
- [Password protected Kubernetes Dashboard] (https://k8s.qzhub.kz/)
- [Password protected Prometheus & Grafana Monitoring] (https://grafana.qzhub.kz)
- [Password protected Kubernetes Structure View] (https://kubeview.qzhub.kz/)
- [Password protected Kubernetes Structure View] [A smoketest utility shows Cluster health, configurations & versions] (https://smoketest.qzhub.kz/)

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

## Supported Linux Distributions
- **CentOS/RHEL** 7, 8 (experimental: see [centos 8 notes](docs/centos8.md))
Note: The list of validated [docker versions](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker) is 1.13.1, 17.03, 17.06, 17.09, 18.06, 18.09 and 19.03. The recommended docker version is 19.03. The kubelet might break on docker's non-standard version numbering (it no longer uses semantic versioning). To ensure auto-updates don't break your cluster look into e.g. yum versionlock plugin or apt pin).

## Author
Created by Rajesh Ramasamy (rajinovat@gmail.com).

Copyright 2021, Cloud Native Solutions Pvt.Ltd  Distributed under Apache License Version 2.0 ,see LICENSE for details.

##  Disclaimer: 

Copyright (c) 2021  "copyright notice checker" Authors. All rights reserved.

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
