# Linux
## rke2-server config

```
mkdir -p /var/lib/rancher/rke2/server/manifests/
curl https://raw.githubusercontent.com/nickgerace/vista/main/calico-vxlan.yaml -o /var/lib/rancher/rke2/server/manifests/calico-vxlan.yaml

mkdir -p /etc/rancher/rke2
nano /etc/rancher/rke2/config.yaml
```

#### /etc/rancher/rke2/config.yaml

```yaml
disable: "rke2-canal"
node-ip:
  - "<priv-ip>"
node-external-ip:
  - "<ext-ip>"
```

```
curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.20.6+rke2r1 sh - 

systemctl enable rke2-server.service
systemctl start rke2-server.service

sleep 15
cat /var/lib/rancher/rke2/server/node-token

export PATH=$PATH:/var/lib/rancher/rke2/bin/
export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"
crictl config --set runtime-endpoint=unix:///run/k3s/containerd/containerd.sock
```

## rke2-agent

```
mkdir -p /etc/rancher/rke2/

nano /etc/rancher/rke2/config.yaml
```
#### /etc/rancher/rke2/config.yaml
##### use internal OR external IP of the rke2-server for `server`
##### use output of `cat /var/lib/rancher/rke2/server/node-token` from rke2-server for the token

```
server: <https://IP:9345>
token: <>
```

```
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" INSTALL_RKE2_VERSION=v1.20.6+rke2r1 sh -
systemctl enable rke2-agent.service
systemctl start rke2-agent.service

export PATH=$PATH:/var/lib/rancher/rke2/bin/
crictl config --set runtime-endpoint=unix:///run/k3s/containerd/containerd.sock
```

## Calico on Linux setup

### install calicoctl and configure calico
```
curl -o /usr/local/bin/calicoctl -O -L  "https://github.com/projectcalico/calicoctl/releases/download/v3.19.0/calicoctl" 
chmod +x /usr/local/bin/calicoctl
calicoctl ipam configure --strictaffinity=true
export FELIX_AWSSRCDSTCHECK="DoNothing"
export FELIX_ALLOWVXLANPACKETSFROMWORKLOADS=true
export FELIX_IPV6SUPPORT=false
calicoctl get felixConfiguration default -o yaml --export > ~/config.yaml
nano ~/config.yaml
```

#### ~/config.yaml

```yaml
apiVersion: projectcalico.org/v3
kind: FelixConfiguration
metadata:
  creationTimestamp: null
  name: default
spec:
  bpfLogLevel: ""
  logSeverityScreen: Info
  reportingInterval: 0s
  vxlanEnabled: true
  ipv6Support: false
  allowVXLANPacketsFromWorkloads: true
  awsSrcDstCheck: "DoNothing"
```

# replace default calico configuration with our custom required for windows calico config
`calicoctl replace -f ~/config.yaml`



# Windows

### Use the default kubeconfig from rke2-server
#### substitute in the internal OR external IP/DNS for the `server:` line

> Copy /etc/rancher/rke2/rke2.yaml on your machine located outside the cluster as ~/.kube/config. Then replace 127.0.0.1 with the IP or hostname of your RKE2 server. kubectl can now manage your RKE2 cluster.


##### located at `c:\k\config`
```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <>
    server: https://RKE2_SERVER_IP:6443
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    client-certificate-data: <>
    client-key-data: <>
```

### setup your windows node

```
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/rke2-win-node-setup.ps1 -OutFile c:\rke2-win-node-setup.ps1
powershell c:\rke2-win-node-setup.ps1
```

### Use the rke2 team's Calico windows install script instead of the upstream

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/install-calico-windows.ps1 -OutFile c:\install-calico-windows.ps1
powershell c:\install-calico-windows.ps1 -DownloadOnly yes -KubeVersion 1.20.6 -ServiceCidr "10.42.0.0/16" -DNSServerIPs 10.43.0.10
```

#### Modify config.ps1 with your NODENAME and uncomment
##### OR
#### Set your nodename using the output of the install-calico-windows.ps1
`$env:NODENAME="<>"`

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/calico-config.ps1 -OutFile c:\CalicoWindows\config.ps1
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/install-calico.ps1 -OutFile c:\CalicoWindows\install-calico.ps1
```

#### Setup resolv.conf for kubelet

```powershell
New-Item -ItemType Directory -Path c:\k\etc -Force > $null
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/resolv.conf -OutFile c:\k\etc\resolv.conf
```

#### Start Kubelet
##### example startup args for k8s components on windows
`Start-Job -ScriptBlock { c:\k\kubelet.exe --v=4 --config=c:\k\kubelet-config.yaml --kubeconfig=c:\k\config --hostname-override=$(hostname) --container-runtime=remote --container-runtime-endpoint='npipe:////./pipe/containerd-containerd' --cluster-dns=10.43.0.10 --feature-gates="WinOverlay=true" }`

#### Install Calico, requires kubelet to be running to verify configuration (kubelet will be complaining that CNI networks are not ready)
`powershell c:\CalicoWindows\install-calico.ps1`

##### for kube-proxy, will need the source-vip for kube-proxy generated from the above
##### working source-vip.ps1 ref: https://gist.githubusercontent.com/rosskirkpat/daebb1b489299c9e12f76054e154b519/raw/464e69634955f32689396cff79f2a773d8d6d6b0/source-vip.ps1


##### find source-vip for kube-proxy
```powershell
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/source-vip.ps1 -OutFile c:\opt\cni\bin\source-vip.ps1
Get-Content c:\opt\cni\bin\sourceVipRequest.json
```

#### Start kube-proxy
```
c:\k\kube-proxy.exe --kubeconfig=c:\k\config --source-vip 192.168.104.66 --hostname-override=$(hostname) --proxy-mode=kernelspace --v=4 --cluster-cidr=10.42.0.0/16 --network-name=Calico --feature-gates="WinOverlay=true" --masquerade-all="false"```

