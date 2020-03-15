#!/bin/bash

export K8S_PACKAGE_NAME=${1-"kubernetes-server-linux-amd64.tar.gz"}
export HOSTNAME=${2-"k8s-master"}
export CERT_SCRIPT=k8s-master-certs.sh
export CONFIG_SCRIPT=k8s-master-config.sh
export CURRENT_DIR=$(pwd)



# check if the files exists
function echo_red() {
    echo -e "\033[31m$1\033[0m"
}

if [ ! -e "$K8S_PACKAGE_NAME" ]; then
    echo_red "$K8S_PACKAGE_NAME no such file"
    exit
fi

if [ ! -e "$CERT_SCRIPT" ]; then
    echo_red "$CERT_SCRIPT no such file"
    exit
fi

if [ ! -e "$CONFIG_SCRIPT" ]; then
    echo_red "$CONFIG_SCRIPT no such file"
    exit
fi



if [ ! -d "/etc/kubernetes/cert" ]; then
    mkdir /etc/kubernetes/cert -pv
fi
mv openssl.cnf /etc/kubernetes/cert
cd /etc/kubernetes/cert



# create certificate files
bash $CURRENT_DIR/$CERT_SCRIPT
# create configuration files
bash $CURRENT_DIR/$CONFIG_SCRIPT



useradd -r kube
mkdir /var/run/kubernetes -pv
chown kube.kube /var/run/kubernetes


# create token file
BOOTSTRAP_TOKEN="$(head -c 6 /dev/urandom | md5sum | head -c 6).$(head -c 16 /dev/urandom | md5sum | head -c 16)"
echo "$BOOTSTRAP_TOKEN,system:bootstrapper,10001,\"system:bootstrappers\"" > /etc/kubernetes/token.csv



# move binary to directory
cd $CURRENT_DIR
mkdir /usr/local/kubernetes/ -pv
tar -xf $K8S_PACKAGE_NAME
cd kubernetes/server/bin/
mv kube-apiserver kube-controller-manager kube-scheduler /usr/local/kubernetes/
mv kubectl /usr/bin/



if [ $? -ne 0 ]; then
    echo_red "not have kubectl command"
    exit
fi



# create .kube/config file
kubectl=/usr/bin/kubectl
kubectl config set-cluster kubernetes --server="https://$HOSTNAME:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt --embed-certs=true
kubectl config set-credentials k8s --client-certificate=/etc/kubernetes/cert/apiserver-kubelet-client.crt --client-key=/etc/kubernetes/cert/apiserver-kubelet-client.key --embed-certs=true
kubectl config set-context k8s@kubernetes --cluster=kubernetes --user=k8s
kubectl config use-context k8s@kubernetes
kubectl create clusterrolebinding system:bootstrapper --user=system:bootstrapper --clusterrole=system:node-bootstrapper



cd /etc/kubernetes

# controller-manager
kubectl config --kubeconfig=controller-manager.conf set-cluster kubernetes --server="https://$HOSTNAME:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt --embed-certs=true
kubectl config --kubeconfig=controller-manager.conf set-credentials system:kube-controller-manager --client-certificate=/etc/kubernetes/cert/kube-controller-manager.crt --client-key=/etc/kubernetes/cert/kube-controller-manager.key --embed-certs=true
kubectl config --kubeconfig=controller-manager.conf set-context system:kube-controller-manager@kubernetes --cluster=kubernetes --user=system:kube-controller-manager
kubectl config --kubeconfig=controller-manager.conf use-context system:kube-controller-manager@kubernetes

chmod 644 controller-manager.conf



# scheduler
kubectl config --kubeconfig=scheduler.conf set-cluster kubernetes --server="https://$HOSTNAME:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt --embed-certs=true
kubectl config --kubeconfig=scheduler.conf set-credentials system:kube-scheduler --client-certificate=/etc/kubernetes/cert/kube-scheduler.crt --client-key=/etc/kubernetes/cert/kube-scheduler.key --embed-certs=true
kubectl config --kubeconfig=scheduler.conf set-context system:kube-scheduler@kubernetes --cluster=kubernetes --user=system:kube-scheduler
kubectl config --kubeconfig=scheduler.conf use-context system:kube-scheduler@kubernetes

chmod 644 scheduler.conf


cd $CURRENT_DIR
