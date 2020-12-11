## 此处的脚本用来执行安装kubernetes。

安装之前先配置主节点到各个node节点的免秘钥，脚本适用于CentOS7。
#### 开始安装：
install-k8s-master.sh 安装master节点上的api-server、controller-manager、scheduler三个组件
```console
bash 01.install-k8s-master.sh kubernetes-server-linux-amd64.tar.gz 192.168.1.20 k8s-master
```
下载cni插件：执行02脚本的时候会用到
```console
wget https://github.com/containernetworking/plugins/releases/download/v0.8.5/cni-plugins-linux-amd64-v0.8.5.tgz
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
bash 04.install-k8s-node.sh master node1
```
#### 其他脚本：
被引用的脚本，不用单独执行。
+ etcd-install.sh 安装etcd的脚本
+ k8s-master-certs.sh 生成证书文件脚本
+ k8s-master-config.sh 生成k8s-master所有的配置文件脚本

#### 安装插件：
安装网络插件：
```console
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

安装CoreDNS：
```console
wget https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/coredns.yaml.sed 
wget https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/deploy.sh
bash deploy.sh -i 10.96.0.10 -r "10.96.0.0/12" -s -t coredns.yaml.sed | kubectl apply -f -
```

解析测试：
```console
~]# kubectl run busybox --image=busybox:1.28 --generator="run-pod/v1" -it --rm -- sh
/ # nslookup kube-dns.kube-system
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
 
Name:      kube-dns.kube-system
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
```
