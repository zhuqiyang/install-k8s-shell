# 此脚本用来安装master节点，用于平时的实验环境

+ install-k8s-master.sh 主脚本，运行这个脚本就行了
+ etcd-install.sh  安装etcd的脚本
+ k8s-master-certs.sh   生成证书文件
+ k8s-master-config.sh  生成k8s-master所有的配置文件
+ install-kubelet-kube-proxy.sh  如果主节点要想运行Pod或与Pod通信则运行这个脚本


```console
sh install-k8s-master.sh 192.168.1.20 kubernetes-server-linux-amd64.tar.gz k8s-master
```
