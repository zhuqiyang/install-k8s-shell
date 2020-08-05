# 此脚本用来安装master节点，用于平时的实验环境

安装之前先配置主节点到各个node节点的免秘钥，脚本适用于Centos7

01.install-k8s-master.sh 安装master节点上的api-server、controller-manager、scheduler三个组件
```console
bash 01.install-k8s-master.sh 192.168.1.20 kubernetes-server-linux-amd64.tar.gz k8s-master
```
安装主节点的kubelet、kube-proxy组件
```console
bash 02.install-kubelet-kube-proxy.sh
```
安装命令行补全工具
```console
bash 03.install-completion.sh
```
安装node节点上的kubelet、kube-proxy
```console
bash 04.install-k8s-node.sh
```
+ etcd-install.sh 安装etcd的脚本
+ k8s-master-certs.sh 生成证书文件
+ k8s-master-config.sh 生成k8s-master所有的配置文件
