#!/bin/bash
###################################
#                                 #
#       install kube-proxy        #
#                                 #
###################################


cp kube-proxy.conf /etc/kubernetes/
if [ ! -e "/etc/kubernetes/kube-proxy.conf" ]; then
        echo -e "\033[31m  file /etc/kubernetes/kube-proxy.conf not exists   \033[0m"
fi


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

systemctl start kube-proxy.service
systemctl enable kube-proxy.service

