#!/bin/bash
#
# install kubelet
#

export CNI_PACKAGE=${1-"cni-plugins-linux-amd64-v0.8.5.tgz"}

function echo_red() {
    echo -e "\033[31m$1\033[0m"
}


mkdir /var/lib/kubelet -pv
mkdir /etc/kubernetes/{cert,manifests} -pv

# ca.crt
if [ -e "ca.crt" ]; then
    cp ca.crt /etc/kubernetes/cert/ca.crt
else
    echo_red "no such file ca.crt"
    exit
fi

# bootstrap.conf
if [ -e "bootstrap.conf" ]; then
    cp bootstrap.conf /etc/kubernetes/
    chmod 644 /etc/kubernetes/bootstrap.conf
else
    echo_red "no such file bootstrap.conf"
    exit
fi

# cni-plugins
if [ -e "$CNI_PACKAGE" ]; then
    mkdir -p /opt/cni/bin
    tar -xf $CNI_PACKAGE -C /opt/cni/bin/
else
    echo_red "no such file $CNI_PACKAGE"
    exit
fi

# kubelet binary
if [ ! -e "/usr/local/kubernetes/kubelet" ]; then
    echo_red "no such file kubelet"
    exit
fi




#
#  ||                     ||
#  || configuration files ||
#  VV                     VV
#

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






