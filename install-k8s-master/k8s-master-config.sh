#!/bin/bash

DIR="/etc/kubernetes/"

if [ ! -d "$DIR" ]; then
    mkdir $DIR -pv
fi

cat > /etc/kubernetes/config <<EOF
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"
 
# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=1"
 
# Should this cluster be allowed to run privileged docker containers
#KUBE_ALLOW_PRIV="--allow-privileged=true"
EOF

cat > /usr/lib/systemd/system/kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service
 
[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/apiserver
User=kube
ExecStart=/usr/local/kubernetes/kube-apiserver \\
        \$KUBE_LOGTOSTDERR \\
        \$KUBE_LOG_LEVEL \\
        \$KUBE_ETCD_SERVERS \\
        \$KUBE_API_ADDRESS \\
        \$KUBE_API_PORT \\
        \$KUBELET_PORT \\
        \$KUBE_ALLOW_PRIV \\
        \$KUBE_SERVICE_ADDRESSES \\
        \$KUBE_ADMISSION_CONTROL \\
        \$KUBE_API_ARGS
Restart=on-failure
Type=notify
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/kubernetes/apiserver <<EOF
###
# kubernetes system config
#
# The following values are used to configure the kube-apiserver
#
 
# The address on the local server to listen to.
KUBE_API_ADDRESS="--advertise-address=0.0.0.0"
 
# The port on the local server to listen on.
KUBE_API_PORT="--secure-port=6443 --insecure-port=0"
 
# Comma separated list of nodes in the etcd cluster
KUBE_ETCD_SERVERS="--etcd-servers=https://etcd:2379"
 
# Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.96.0.0/12"
 
# default admission control policies
KUBE_ADMISSION_CONTROL="--enable-admission-plugins=NodeRestriction"
 
# Add your own!
KUBE_API_ARGS="--authorization-mode=Node,RBAC \\
    --client-ca-file=/etc/kubernetes/cert/ca.crt \\
    --enable-bootstrap-token-auth=true \\
    --etcd-cafile=/etc/etcd/cert/ca-client.crt \\
    --etcd-certfile=/etc/etcd/cert/etcd_client.crt \\
    --etcd-keyfile=/etc/etcd/cert/etcd_client.key \\
    --kubelet-client-certificate=/etc/kubernetes/cert/apiserver-kubelet-client.crt \\
    --kubelet-client-key=/etc/kubernetes/cert/apiserver-kubelet-client.key \\
    --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \\
    --proxy-client-cert-file=/etc/kubernetes/cert/front-proxy-client.crt \\
    --proxy-client-key-file=/etc/kubernetes/cert/front-proxy-client.key \\
    --requestheader-allowed-names=front-proxy-client \\
    --requestheader-client-ca-file=/etc/kubernetes/cert/front-proxy-ca.crt \\
    --requestheader-extra-headers-prefix=X-Remote-Extra- \\
    --requestheader-group-headers=X-Remote-Group \\
    --requestheader-username-headers=X-Remote-User\\
    --service-account-issuer=https://kubernetes.default.svc.cluster.local \\
    --service-account-signing-key-file=/etc/kubernetes/cert/sa.key \\
    --service-account-key-file=/etc/kubernetes/cert/sa.pub \\
    --tls-cert-file=/etc/kubernetes/cert/apiserver.crt \\
    --tls-private-key-file=/etc/kubernetes/cert/apiserver.key \\
    --token-auth-file=/etc/kubernetes/token.csv"
EOF

cat > /usr/lib/systemd/system/kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
 
[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/controller-manager
User=kube
ExecStart=/usr/local/kubernetes/kube-controller-manager \\
        \$KUBE_LOGTOSTDERR \\
        \$KUBE_LOG_LEVEL \\
        \$KUBE_MASTER \\
        \$KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/kubernetes/controller-manager <<EOF
###
# The following values are used to configure the kubernetes controller-manager
 
# defaults from config and apiserver should be adequate
 
# Add your own!
KUBE_CONTROLLER_MANAGER_ARGS="--bind-address=127.0.0.1 \\
    --allocate-node-cidrs=true \\
    --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf \\
    --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf \\
    --client-ca-file=/etc/kubernetes/cert/ca.crt \\
    --cluster-cidr=10.244.0.0/16 \\
    --cluster-signing-cert-file=/etc/kubernetes/cert/ca.crt \\
    --cluster-signing-key-file=/etc/kubernetes/cert/ca.key \\
    --controllers=*,bootstrapsigner,tokencleaner \\
    --kubeconfig=/etc/kubernetes/controller-manager.conf \\
    --leader-elect=true \\
    --node-cidr-mask-size=24 \\
    --requestheader-client-ca-file=/etc/kubernetes/cert/front-proxy-ca.crt \\
    --root-ca-file=/etc/kubernetes/cert/ca.crt \\
    --service-account-private-key-file=/etc/kubernetes/cert/sa.key \\
    --use-service-account-credentials=true"
EOF

cat > /usr/lib/systemd/system/kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler Plugin
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
 
[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/scheduler
User=kube
ExecStart=/usr/local/kubernetes/kube-scheduler \\
        \$KUBE_LOGTOSTDERR \\
        \$KUBE_LOG_LEVEL \\
        \$KUBE_MASTER \\
        \$KUBE_SCHEDULER_ARGS
Restart=on-failure
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/kubernetes/scheduler <<EOF
###
# kubernetes scheduler config
 
# default config should be adequate
 
# Add your own!
KUBE_SCHEDULER_ARGS="--address=127.0.0.1 \\
    --kubeconfig=/etc/kubernetes/scheduler.conf \\
    --leader-elect=true"
EOF
