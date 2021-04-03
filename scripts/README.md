# Production Ready Kubernetes Cluster Using Vagrant

## Overview
![Kubernetes Logo](https://raw.githubusercontent.com/kubernetes-sigs/kubespray/master/docs/img/kubernetes-logo.png)

This repository describes the steps required to setup a multi-node Kubernetes Cluster for Oodo Deployment.

The repository contains a Vagrantfile, [Kubespray](https://github.com/kubernetes-sigs/kubespray) Kubernetes Implementation and bootstrap helm charts to deploy the cluster.

## Cluster Architecture

![Scheme](logo/K8s-Dev-Architecture.png)

## Prerequisites
## Quick Start

To deploy the cluster you can use :

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
