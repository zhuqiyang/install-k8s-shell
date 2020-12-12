## 安装kubernetes的脚本
这个脚本可以快速搭建 kubernetes 集群，适用于k8s 1.20版本，会在节点上安装以下组件。
#### master节点：
+ etcd
+ api-server
+ controller-manager
+ scheduler
+ kubelet (可选)
+ kube-proxy (可选)

#### node节点：
+ kubelet
+ kube-proxy
详细操作见各个目录的README.md
