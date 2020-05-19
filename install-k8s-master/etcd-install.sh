#!/bin/bash
#####################
#                   #
#   install etcd    #
#                   #
#####################



# etcd要监听ip地址
export ETCD_LISTEN_IP=$1


wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum install etcd -y

if [ $? -ne 0 ]; then
    echo "etcd install failre"
    exit;
fi


mkdir /etc/etcd/cert/ -pv
cd /etc/etcd/cert/

cat > /etc/etcd/cert/openssl.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = etcd
EOF


# CA
openssl genrsa -out ca-client.key 2048
openssl req -x509 -new -nodes -key ca-client.key -subj "/CN=etcd" -days 5000 -out ca-client.crt
# etcd服务端使用的证书
openssl genrsa -out etcd_server.key 2048
openssl req -new -key etcd_server.key -subj "/CN=etcd" -out etcd_server.csr -config openssl.cnf
openssl x509 -req -in etcd_server.csr -CA ca-client.crt -CAkey ca-client.key -CAcreateserial -out etcd_server.crt -days 5000 -extensions v3_req -extfile openssl.cnf
# 客户端访问etcd集群使用的证书
openssl genrsa -out etcd_client.key 2048
openssl req -new -key etcd_client.key -subj "/CN=etcd" -out etcd_client.csr -config openssl.cnf
openssl x509 -req -in etcd_client.csr -CA ca-client.crt -CAkey ca-client.key -CAcreateserial -out etcd_client.crt -days 5000 -extensions v3_req -extfile openssl.cnf



cat > /etc/etcd/etcd.conf <<EOF
#[Member]
#ETCD_CORS=""
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
#ETCD_WAL_DIR=""
#ETCD_LISTEN_PEER_URLS="http://localhost:2380"
ETCD_LISTEN_CLIENT_URLS="https://${ETCD_LISTEN_IP}:2379,https://localhost:2379"
#ETCD_MAX_SNAPSHOTS="5"
#ETCD_MAX_WALS="5"
ETCD_NAME="default"
#ETCD_SNAPSHOT_COUNT="100000"
#ETCD_HEARTBEAT_INTERVAL="100"
#ETCD_ELECTION_TIMEOUT="1000"
#ETCD_QUOTA_BACKEND_BYTES="0"
#ETCD_MAX_REQUEST_BYTES="1572864"
#ETCD_GRPC_KEEPALIVE_MIN_TIME="5s"
#ETCD_GRPC_KEEPALIVE_INTERVAL="2h0m0s"
#ETCD_GRPC_KEEPALIVE_TIMEOUT="20s"
#
#[Clustering]
#ETCD_INITIAL_ADVERTISE_PEER_URLS="http://localhost:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://etcd:2379,https://localhost:2379"
#ETCD_DISCOVERY=""
#ETCD_DISCOVERY_FALLBACK="proxy"
#ETCD_DISCOVERY_PROXY=""
#ETCD_DISCOVERY_SRV=""
#ETCD_INITIAL_CLUSTER="default=http://localhost:2380"
#ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
#ETCD_INITIAL_CLUSTER_STATE="new"
#ETCD_STRICT_RECONFIG_CHECK="true"
#ETCD_ENABLE_V2="true"
#
#[Proxy]
#ETCD_PROXY="off"
#ETCD_PROXY_FAILURE_WAIT="5000"
#ETCD_PROXY_REFRESH_INTERVAL="30000"
#ETCD_PROXY_DIAL_TIMEOUT="1000"
#ETCD_PROXY_WRITE_TIMEOUT="5000"
#ETCD_PROXY_READ_TIMEOUT="0"
#
#[Security]
ETCD_CERT_FILE="/etc/etcd/cert/etcd_server.crt"
ETCD_KEY_FILE="/etc/etcd/cert/etcd_server.key"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/etc/etcd/cert/ca-client.crt"
#ETCD_AUTO_TLS="false"
#ETCD_PEER_CERT_FILE=""
#ETCD_PEER_KEY_FILE=""
#ETCD_PEER_CLIENT_CERT_AUTH="false"
#ETCD_PEER_TRUSTED_CA_FILE=""
#ETCD_PEER_AUTO_TLS="false"
#
#[Logging]
#ETCD_DEBUG="false"
#ETCD_LOG_PACKAGE_LEVELS=""
#ETCD_LOG_OUTPUT="default"
#
#[Unsafe]
#ETCD_FORCE_NEW_CLUSTER="false"
#
#[Version]
#ETCD_VERSION="false"
#ETCD_AUTO_COMPACTION_RETENTION="0"
#
#[Profiling]
#ETCD_ENABLE_PPROF="false"
#ETCD_METRICS="basic"
#
#[Auth]
#ETCD_AUTH_TOKEN="simple"
EOF


systemctl enable etcd
systemctl start etcd
systemctl status etcd

