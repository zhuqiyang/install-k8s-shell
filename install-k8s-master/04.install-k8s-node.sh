#!/bin/bash

export MASTER_NAME=$1
export NODE_NAME=$2



if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
cat <<EOF

    bash $0 master node1

EOF
exit
fi

if [ ! -d "/etc/kubernetes" ]; then
	echo "directory /etc/kubernetes is not exists"
	exit
fi

if [ ! -e "/etc/kubernetes/token.csv" ]; then
	echo "file token.csv is not exists"
	exit
fi

if [ ! -e "./kubernetes/server/bin/kubelet" ]; then
	echo "binary file kubelet is not exists"
	exit
fi

if [ ! -e "./kubernetes/server/bin/kube-proxy" ]; then
	echo "binary file kube-proxy is not exists"
	exit
fi

if [ ! -e "/etc/kubernetes/cert/ca.crt" ]; then
	echo "file ca.crt is not exists"
	exit
fi

if ! ssh root@$NODE_NAME 'date'; then
	echo "ssh root@$NODE_NAME is not working"
	exit
fi

token=$(cat /etc/kubernetes/token.csv | awk -F ',' '{print $1}')

kubectl config --kubeconfig=bootstrap.conf set-cluster kubernetes --server="https://$MASTER_NAME:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt
kubectl config --kubeconfig=bootstrap.conf set-credentials system:bootstrapper --token=$token
kubectl config --kubeconfig=bootstrap.conf set-context system:bootstrapper@kubernetes --user=system:bootstrapper --cluster=kubernetes
kubectl config --kubeconfig=bootstrap.conf use-context system:bootstrapper@kubernetes

kubectl config --kubeconfig=kube-proxy.conf set-cluster kubernetes --server="https://$MASTER_NAME:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt --embed-certs=true
kubectl config --kubeconfig=kube-proxy.conf set-credentials system:kube-proxy --client-certificate=/etc/kubernetes/cert/kube-proxy.crt --client-key=/etc/kubernetes/cert/kube-proxy.key --embed-certs=true
kubectl config --kubeconfig=kube-proxy.conf set-context system:kube-proxy@kubernetes --cluster=kubernetes --user=system:kube-proxy
kubectl config --kubeconfig=kube-proxy.conf use-context system:kube-proxy@kubernetes


cp /etc/kubernetes/cert/ca.crt ../install-k8s-node/
cp ./{bootstrap.conf,kube-proxy.conf} ../install-k8s-node/
cp ./kubernetes/server/bin/{kubelet,kube-proxy} ../install-k8s-node/
cp /usr/lib/systemd/system/docker.service ../install-k8s-node/
cp $(ls cni-plugins-linux-amd64-v*.tgz) ../install-k8s-node/

# copy shell script
scp -rp ../install-k8s-node/ root@$NODE_NAME:/root

# install k8s for node
ssh root@$NODE_NAME 'cd /root/install-k8s-node/; bash 01.install-k8s-node.sh'
ssh root@$NODE_NAME 'cd /root/install-k8s-node/; bash 02.install-kubelet.sh'
ssh root@$NODE_NAME 'cd /root/install-k8s-node/; bash 03.install-kube-proxy.sh'
