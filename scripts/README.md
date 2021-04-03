# Production Ready Kubernetes Cluster Using Vagrant

## Overview
![Kubernetes Logo](https://raw.githubusercontent.com/kubernetes-sigs/kubespray/master/docs/img/kubernetes-logo.png)

This project describes the steps required to setup a multi-node Kubernetes Cluster for Oodo Deployment.
The repository contains a Vagrantfile, [Kubespray](https://github.com/kubernetes-sigs/kubespray), a Kubernetes Implementation and bootstrap helm charts to deploy the cluster. The automation framework implemented in this project will provision a Production ready full blown multi-node Kubernets Cluster under 30 minutes with Enterprise grade monitoring capability using [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/), [Prometheus & Grafana](https://grafana.com/grafana/dashboards/315), [Kubeview](https://github.com/benc-uk/kubeview).
The implementation also includes Dynamic volume provisioning which allows storage volumes to be created on-demand. Without dynamic provisioning, cluster administrators have to manually make calls to their cloud or storage provider to create new storage volumes, and then create [PersistentVolume objects](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) to represent them in Kubernetes.The dynamic provisioning feature eliminates the need for cluster administrators to pre-provision storage. Instead, it automatically provisions storage when it is requested by users. 
Dynamic storage provisioners are enabled using Local Path Provisioner provides a way for the Kubernetes users to utilize the local storage in each node. Based on the user configuration, the Local Path Provisioner will create `hostPath` based persistent volume on the node automatically. It utilizes the features introduced by Kubernetes [Local Persistent Volume feature](https://kubernetes.io/blog/2018/04/13/local-persistent-volumes-beta/), but make it a simpler solution than the built-in `local` volume feature in Kubernetes.

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
## Quickstart

To deploy a multi-node Kubernetes Deployment run the following steps:
Update [machines.yaml] (scripts/machines.yml) describes the node structure
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


## Supported Linux Distributions

- **Debian** Buster, Jessie, Stretch, Wheezy
- **Ubuntu** 16.04, 18.04, 20.04
- **CentOS/RHEL** 7, 8 (experimental: see [centos 8 notes](docs/centos8.md))
- **Fedora** 31, 32
- **Fedora CoreOS** (experimental: see [fcos Note](docs/fcos.md))
- **openSUSE** Leap 42.3/Tumbleweed
- **Oracle Linux** 7, 8 (experimental: [centos 8 notes](docs/centos8.md) apply)

Note: The list of validated [docker versions](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker) is 1.13.1, 17.03, 17.06, 17.09, 18.06, 18.09 and 19.03. The recommended docker version is 19.03. The kubelet might break on docker's non-standard version numbering (it no longer uses semantic versioning). To ensure auto-updates don't break your cluster look into e.g. yum versionlock plugin or apt pin).

## Requirements

- **Minimum required version of Kubernetes is v1.19**
