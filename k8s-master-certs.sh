#!/bin/bash
#
# create kubernetes certificate files.
#


if [ ! -e "openssl.cnf" ]; then
	echo "no openssl.cnf"
	exit
fi


#
# example:
# $1 "ca"
# $2 "/CN=k8s-ca"
#
function openssl_ca() {
    openssl genrsa -out $1.key 2048
    openssl req -x509 -new -nodes -key $1.key -subj "$2" -days 5000 -out $1.crt
}


#
# example:
# $1 "ca"
# $2 "apiserver"
# $3 "/CN=kube-apiserver"
#
function openssl_k8s() {
    openssl genrsa -out $2.key 2048
    openssl req -new -key $2.key -subj "$3" -out $2.csr -config openssl.cnf
    openssl x509 -req -in $2.csr -CA $1.crt -CAkey $1.key -CAcreateserial -out $2.crt -days 5000 -extensions v3_req -extfile openssl.cnf
}


openssl_ca "ca" "/CN=k8s-ca"
openssl_k8s "ca" "apiserver" "/CN=kube-apiserver"
openssl_k8s "ca" "apiserver-kubelet-client" "/CN=kube-apiserver-kubelet-client/O=system:masters"
openssl_k8s "ca" "kube-controller-manager" "/CN=system:kube-controller-manager"
openssl_k8s "ca" "kube-scheduler" "/CN=system:kube-scheduler"
openssl_k8s "ca" "kube-proxy" "/CN=system:kube-proxy"

openssl_ca "front-proxy-ca" "/CN=front-proxy-ca"
openssl_k8s "front-proxy-ca" "front-proxy-client" "/CN=front-proxy-client"


openssl genrsa -out sa.key 2048
openssl rsa -in sa.key -pubout -out sa.pub
