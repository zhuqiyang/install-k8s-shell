# 此脚本用来安装master节点，用于平时的实验环境

安装好etcd之后运行install-k8s-master.sh

`sh install-k8s-master.sh kubernetes-server-linux-amd64.tar.gz k8s-master`

运行脚本后把 /etc/kubernetes/apiserver 文件中的etcd修改一下

### 启动k8s：
`systemctl start kube-apiserver.service`

### 绑定权限
`kubectl create clusterrolebinding system:bootstrapper --user=system:bootstrapper --clusterrole=system:node-bootstrapper`

### 启动controller-manager
`systemctl start kube-controller-manager.service`

### 启动scheduler
`systemctl start kube-scheduler.service`

## 备注

k8s-master-certs.sh 生成证书文件
k8s-master-config.sh 生成k8s-master所有的配置文件
