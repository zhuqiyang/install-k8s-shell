#!/bin/bash
#
#    install k8s node
#

if [ ! -e /usr/local/kubernetes/kubelet ]; then
	echo "binary file kubelet is not exists"
	exit
fi

if [ ! -e /usr/local/kubernetes/kube-proxy ]; then
	echo "binary file kube-proxy is not exists"
	exit
fi

# set timezone
systemctl start chronyd.service 
systemctl enable chronyd.service
timedatectl set-timezone Asia/Shanghai
chronyc -a makestep
timedatectl status


# install docker-ce
wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install docker-ce -y
cp docker.service /usr/lib/systemd/system/docker.service

systemctl daemon-reload
systemctl start docker
docker info


# open bridge
cat >> /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl -p

