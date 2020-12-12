#!/bin/bash
################################
#                              #
#         install docker       #
#                              #
################################

mkdir /usr/local/kubernetes/ -pv
cp kubelet /usr/local/kubernetes/
cp kube-proxy /usr/local/kubernetes/


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
systemctl enable docker
docker info


# open bridge
cat >> /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl -p
