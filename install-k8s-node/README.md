## 安装node节点
配置好主机名称解析到各个节点， 在主节点上执行04脚本即可安装node节点，也可在node节点上执行04脚本安装。

#### 开机启动
```console
systemctl enable docker.service
systemctl enable kubelet.service
systemctl enable kube-proxy.service
```
