#!/bin/bash
#
# install k8s node
#

export HOSTNAME=${1-"k8s-node01"}
export K8S_PACKAGE=${2-"kubernetes-server-linux-amd64.tar.gz"}
export CURRENT_DIR=$(pwd)


# set timezone
systemctl start chronyd.service 
systemctl enable chronyd.service
timedatectl set-timezone Asia/Shanghai
chronyc -a makestep
timedatectl status


# install docker-ce
wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install docker-ce -y

sed -i '/ExecStart=/a\ExecStartPost=/usr/sbin/iptables -P FORWARD ACCEPT' /usr/lib/systemd/system/docker.service
# proxy
sed -i '/ExecStart=/i\Environment=HTTPS_PROXY=http://192.168.0.12:8118' /usr/lib/systemd/system/docker.service
sed -i '/ExecStart=/i\Environment=NO_PROXY=127.0.0.0/8,192.168.1.0/24' /usr/lib/systemd/system/docker.service



systemctl daemon-reload
systemctl start docker
docker info

# open bridge
cat >> /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl -p




if [ -e "$K8S_PACKAGE" ]; then
    tar -xf $K8S_PACKAGE
fi

# move binary
mkdir /usr/local/kubernetes -pv
cd kubernetes/server/bin/
mv kube-proxy kubelet /usr/local/kubernetes/
cd $CURRENT_DIR




