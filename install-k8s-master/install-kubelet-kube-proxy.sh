#!/bin/bash

export CNI_PACKAGE=${1-"cni-plugins-linux-amd64-v0.8.5.tgz"}
export PROXY_IP=${2-"192.168.0.12"}



function echo_red() {
    echo -e "\033[31m$1\033[0m"
}

# check binary file exists
if [ ! -e "kubernetes" ]; then
    echo "k8s binary file not exists!"
    exit
fi

# check if cni-plugins exists
if [ ! -e "$CNI_PACKAGE" ]; then
    echo_red "no such file $CNI_PACKAGE"
    exit
fi

# enter proxy ip
if [ ! -z "$PROXY_IP" ]; then
    read -p "Please enter proxy ip: " PROXY_IP
fi


#########################
#                       #
#   install docker-ce   #
#                       #
#########################

wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install docker-ce -y


sed -i '/ExecStart=/a\ExecStartPost=/usr/sbin/iptables -P FORWARD ACCEPT' /usr/lib/systemd/system/docker.service
# proxy
sed -i "/ExecStart=/iEnvironment=HTTPS_PROXY=http://${PROXY_IP}:8118" /usr/lib/systemd/system/docker.service
sed -i '/ExecStart=/i\Environment=NO_PROXY=127.0.0.0/8,192.168.1.0/24' /usr/lib/systemd/system/docker.service


systemctl daemon-reload
systemctl start docker
docker info


cat >> /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl -p




#####################
#                   #
#  install kubelet  #
#                   #
#####################

mkdir /var/lib/kubelet -pv
mkdir /etc/kubernetes/manifests

# move binary
cp kubernetes/server/bin/kube-proxy kubernetes/server/bin/kubelet /usr/local/kubernetes/

# cni-plugins install
mkdir -p /opt/cni/bin
tar -xf $CNI_PACKAGE -C /opt/cni/bin/


# bootstrap.conf
token=$(awk -F ',' '{print $1}' /etc/kubernetes/token.csv)
kubectl config --kubeconfig=bootstrap.conf set-cluster kubernetes --server="https://k8s-master:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt --embed-certs=true
kubectl config --kubeconfig=bootstrap.conf set-credentials system:bootstrapper --token=${token}
kubectl config --kubeconfig=bootstrap.conf set-context system:bootstrapper@kubernetes --user=system:bootstrapper --cluster=kubernetes
kubectl config --kubeconfig=bootstrap.conf use-context system:bootstrapper@kubernetes
cp bootstrap.conf /etc/kubernetes/
chmod 644 /etc/kubernetes/bootstrap.conf



#  ||                     ||
#  || configuration files ||
#  VV                     VV

cat > /usr/lib/systemd/system/kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service
 
[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStart=/usr/local/kubernetes/kubelet \\
        \$KUBE_LOGTOSTDERR \\
        \$KUBE_LOG_LEVEL \\
        \$KUBELET_API_SERVER \\
        \$KUBELET_ADDRESS \\
        \$KUBELET_PORT \\
        \$KUBELET_HOSTNAME \\
        \$KUBE_ALLOW_PRIV \\
        \$KUBELET_ARGS
Restart=on-failure
KillMode=process
RestartSec=10
 
[Install]
WantedBy=multi-user.target
EOF


cat > /etc/kubernetes/kubelet <<EOF
# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
KUBELET_ADDRESS="--address=0.0.0.0"
 
# The port for the info server to serve on
# KUBELET_PORT="--port=10250"
 
# Add your own!
KUBELET_ARGS="--network-plugin=cni \\
    --config=/var/lib/kubelet/config.yaml \\
    --kubeconfig=/etc/kubernetes/kubelet.conf \\
    --bootstrap-kubeconfig=/etc/kubernetes/bootstrap.conf"
EOF



cat > /var/lib/kubelet/config.yaml <<EOF
address: 0.0.0.0
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/cert/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
cgroupDriver: cgroupfs
cgroupsPerQOS: true
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local
configMapAndSecretChangeDetectionStrategy: Watch
containerLogMaxFiles: 5
containerLogMaxSize: 10Mi
contentType: application/vnd.kubernetes.protobuf
cpuCFSQuota: true
cpuCFSQuotaPeriod: 100ms
cpuManagerPolicy: none
cpuManagerReconcilePeriod: 10s
enableControllerAttachDetach: true
enableDebuggingHandlers: true
enforceNodeAllocatable:
- pods
eventBurst: 10
eventRecordQPS: 5
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
evictionPressureTransitionPeriod: 5m0s
failSwapOn: false
fileCheckFrequency: 20s
hairpinMode: promiscuous-bridge
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 20s
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
imageMinimumGCAge: 2m0s
iptablesDropBit: 15
iptablesMasqueradeBit: 14
kind: KubeletConfiguration
kubeAPIBurst: 10
kubeAPIQPS: 5
makeIPTablesUtilChains: true
maxOpenFiles: 1000000
maxPods: 110
nodeLeaseDurationSeconds: 40
nodeStatusUpdateFrequency: 10s
oomScoreAdj: -999
podPidsLimit: -1
port: 10250
registryBurst: 10
registryPullQPS: 5
resolvConf: /etc/resolv.conf
rotateCertificates: true
runtimeRequestTimeout: 2m0s
serializeImagePulls: true
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 4h0m0s
syncFrequency: 1m0s
volumeStatsAggPeriod: 1m0s
EOF





#########################
#                       #
#  install kube-proxy   #
#                       #
#########################

kubectl config --kubeconfig=kube-proxy.conf set-cluster kubernetes --server="https://k8s-master:6443" --certificate-authority=/etc/kubernetes/cert/ca.crt --embed-certs=true
kubectl config --kubeconfig=kube-proxy.conf set-credentials system:kube-proxy --client-certificate=/etc/kubernetes/cert/kube-proxy.crt --client-key=/etc/kubernetes/cert/kube-proxy.key --embed-certs=true
kubectl config --kubeconfig=kube-proxy.conf set-context system:kube-proxy@kubernetes --cluster=kubernetes --user=system:kube-proxy
kubectl config --kubeconfig=kube-proxy.conf use-context system:kube-proxy@kubernetes
cp kube-proxy.conf /etc/kubernetes/
chmod 644 /etc/kubernetes/kube-proxy.conf


cat > /usr/lib/systemd/system/kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
 
[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/proxy
ExecStart=/usr/local/kubernetes/kube-proxy \\
            \$KUBE_LOGTOSTDERR \\
            \$KUBE_LOG_LEVEL \\
            \$KUBE_MASTER \\
            \$KUBE_PROXY_ARGS
Restart=on-failure
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
EOF


cat > /etc/kubernetes/proxy <<EOF
###
# kubernetes proxy config
 
# Add your own!
KUBE_PROXY_ARGS="--config=/var/lib/kube-proxy/config.yaml"
EOF

mkdir /var/lib/kube-proxy -pv
cat > /var/lib/kube-proxy/config.yaml <<EOF
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
clientConnection:
  acceptContentTypes: ""
  burst: 10
  contentType: application/vnd.kubernetes.protobuf
  kubeconfig: /etc/kubernetes/kube-proxy.conf
  qps: 5
clusterCIDR: 10.244.0.0/16
configSyncPeriod: 15m0s
conntrack:
  max: null
  maxPerCore: 32768
  min: 131072
  tcpCloseWaitTimeout: 1h0m0s
  tcpEstablishedTimeout: 24h0m0s
enableProfiling: false
healthzBindAddress: 0.0.0.0:10256
hostnameOverride: ""
iptables:
  masqueradeAll: false
  masqueradeBit: 14
  minSyncPeriod: 0s
  syncPeriod: 30s
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: ""
  syncPeriod: 30s
kind: KubeProxyConfiguration
metricsBindAddress: 127.0.0.1:10249
mode: ipvs
nodePortAddresses: null
oomScoreAdj: -999
portRange: ""
EOF



# ipvs.modules
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_mods_dir="/usr/lib/modules/\$(uname -r)/kernel/net/netfilter/ipvs"
for i in \$(ls \$ipvs_mods_dir | grep -o "^[^.]*"); do
    /sbin/modinfo -F filename \$i  &> /dev/null
    if [ \$? -eq 0 ]; then
        /sbin/modprobe \$i
    fi
done
EOF

chmod +x /etc/sysconfig/modules/ipvs.modules
bash /etc/sysconfig/modules/ipvs.modules
lsmod | grep ip_vs


# enable services
systemctl enable kubelet.service
systemctl start kubelet.service
systemctl status kubelet.service

systemctl enable kube-proxy.service
systemctl start kube-proxy.service
systemctl status kube-proxy.service
