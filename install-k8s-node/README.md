# 安装node节点

#### 运行 install-k8s-node.sh 脚本前的准备
+ 配置好主机名称解析到各个节点
+ 到官网[下载k8s二进制文件](https://github.com/kubernetes/kubernetes/releases "下载k8s二进制文件")
+ 需要修改下docker代理的地址

```console
 bash -x install-k8s-node.sh hostname kubernetes-server-linux-amd64.tar.gz
 ```
<br>
#### 运行 k8s-install-kubelet.sh 脚本前准备下面几个文件
+ ca.crt
+ bootstrap.conf

&nbsp;&nbsp;&nbsp;&nbsp;在master节点上运行下面命令：获得 bootstrap.conf 文件（注意修改master节点的名称和token的值）
```console
kubectl config --kubeconfig=bootstrap.conf set-cluster kubernetes --server="https://k8s-master:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt
kubectl config --kubeconfig=bootstrap.conf set-credentials system:bootstrapper --token=54c451.b68dc21e45c57e2a
kubectl config --kubeconfig=bootstrap.conf set-context system:bootstrapper@kubernetes --user=system:bootstrapper --cluster=kubernetes
kubectl config --kubeconfig=bootstrap.conf use-context system:bootstrapper@kubernetes
```
+ cni插件：https://github.com/containernetworking/plugins/releases


##### 运行示例
```console
bash -x k8s-install-kubelet.sh cni-plugins-linux-amd64-v0.8.5.tgz
```

<br>
#### 运行 k8s-install-kube-proxy.sh 脚本前要准备的文件
+ kube-proxy.conf

&nbsp;&nbsp;&nbsp;&nbsp;在master节点上运行下面命令：获取 kube-proxy.conf 文件（注意修改master节点的名称）
```console
kubectl config --kubeconfig=kube-proxy.conf set-cluster kubernetes --server="https://k8s-master:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt --embed-certs=true
kubectl config --kubeconfig=kube-proxy.conf set-credentials system:kube-proxy --client-certificate=/etc/kubernetes/cert/kube-proxy.crt --client-key=/etc/kubernetes/cert/kube-proxy.key --embed-certs=true
kubectl config --kubeconfig=kube-proxy.conf set-context system:kube-proxy@kubernetes --cluster=kubernetes --user=system:kube-proxy
kubectl config --kubeconfig=kube-proxy.conf use-context system:kube-proxy@kubernetes
```
<br>
#### 安装网络插件
&nbsp;&nbsp;&nbsp;&nbsp;这里安装的是flannel
```console
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

#### 开机启动
```console
systemctl enable docker.service
systemctl enable kubelet.service
systemctl enable kube-proxy.service
```
