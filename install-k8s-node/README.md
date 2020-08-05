# 安装node节点

#### 运行 install-k8s-node.sh 脚本前的准备
+ 配置好主机名称解析到各个节点

#### 开机启动

```console
systemctl enable docker.service
systemctl enable kubelet.service
systemctl enable kube-proxy.service
```
