# 安装node节点


#### 运行 k8s-install-kubelet.sh 脚本前准备下面几个文件
ca.crt

获得 bootstrap.conf 文件，在master节点上
```console
kubectl config --kubeconfig=bootstrap.conf set-cluster kubernetes --server="https://k8s-master:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt
kubectl config --kubeconfig=bootstrap.conf set-credentials system:bootstrapper --token=54c451.b68dc21e45c57e2a
kubectl config --kubeconfig=bootstrap.conf set-context system:bootstrapper@kubernetes --user=system:bootstrapper --cluster=kubernetes
kubectl config --kubeconfig=bootstrap.conf use-context system:bootstrapper@kubernetes
```
cni插件：https://github.com/containernetworking/plugins/releases



#### k8s-install-kube-proxy.sh
kube-proxy.conf

获取kube-proxy.conf文件的，在master节点上
```console
kubectl config --kubeconfig=kube-proxy.conf set-cluster kubernetes --server="https://k8s-master:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt --embed-certs=true
kubectl config --kubeconfig=kube-proxy.conf set-credentials system:kube-proxy --client-certificate=/etc/kubernetes/cert/kube-proxy.crt --client-key=/etc/kubernetes/cert/kube-proxy.key --embed-certs=true
kubectl config --kubeconfig=kube-proxy.conf set-context system:kube-proxy@kubernetes --cluster=kubernetes --user=system:kube-proxy
kubectl config --kubeconfig=kube-proxy.conf use-context system:kube-proxy@kubernetes
```
安装网络插件flannel
```console
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
