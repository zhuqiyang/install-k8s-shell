#此脚本用来安装master节点，用于平时的实验环境

安装好etcd之后运行install-k8s-master.sh

sh install-k8s-master.sh kubernetes-server-linux-amd64.tar.gz k8s-master

运行脚本后把 /etc/kubernetes/apiserver 文件中的etcd修改一下

##启动k8s：
systemctl start kube-apiserver.service

`kubectl create clusterrolebinding system:bootstrapper --user=system:bootstrapper --clusterrole=system:node-bootstrapper`

systemctl start kube-controller-manager.service

systemctl start kube-scheduler.service
