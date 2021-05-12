$ProgressPreference = 'SilentlyContinue'
New-Item -ItemType Directory -Path "$Env:ProgramFiles\containerd" -Force > $null
curl.exe -L https://github.com/luthermonson/containerd/releases/download/win-bins/containerd-shim-runhcs-v1.exe -o "$Env:ProgramFiles\containerd\containerd-shim-runhcs-v1.exe"
curl.exe -L https://github.com/luthermonson/containerd/releases/download/win-bins/containerd.exe -o "$Env:ProgramFiles\containerd\containerd.exe"
curl.exe -L https://github.com/luthermonson/containerd/releases/download/win-bins/ctr.exe -o "$Env:ProgramFiles\containerd\ctr.exe"

# Set containerd config.toml
# $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
# $ProcessInfo.FileName = "$Env:ProgramFiles\containerd\containerd.exe"
# $ProcessInfo.RedirectStandardError = $true
# $ProcessInfo.RedirectStandardOutput = $true
# $ProcessInfo.UseShellExecute = $false
# # $ProcessInfo.Arguments = "config default"
# $Process = New-Object System.Diagnostics.Process
# $Process.StartInfo = $ProcessInfo
# $Process.Start() | Out-Null
# $Process.WaitForExit()
# $config = $Process.StandardOutput.ReadToEnd()
# $config = $config -replace "bin_dir = (.)*$", "bin_dir = `"c:/opt/cni/bin`""
# $config = $config -replace "conf_dir = (.)*$", "conf_dir = `"c:/etc/cni/net.d`""
# $config = $config -replace "sandbox_image = `"mcr.microsoft.com/oss/kubernetes/pause:1.4.0`"", "sandbox_image = `"docker.io/rancher/kubelet-pause:v0.1.6`""
# Set-Content -Path $Env:ProgramFiles\containerd\config.toml -Value $config -Force
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/config.toml -OutFile 'C:\Program Files\containerd\config.toml'

Add-MpPreference -ExclusionProcess "$Env:ProgramFiles\containerd\containerd.exe"
Start-Process -FilePath "$Env:ProgramFiles\containerd\containerd.exe" -ArgumentList "--register-service" -NoNewWindow
Sleep 2
Set-Service -Name containerd -StartupType Automatic
Start-Service containerd

$path = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value "$path;$Env:ProgramFiles\containerd"
$env:PATH = "$path;$Env:ProgramFiles\containerd"

# rke2 vars
$env:NODE_NAME = ($hostname)
$env:KUBERNETES_SERVICE_HOST = '10.43.0.1'
$env:KUBERNETES_SERVICE_PORT = '6443'
$env:NO_PROXY = '.svc,.cluster.local,10.42.0.0/16,10.43.0.0/16'
$env:KUBE_NETWORK = "Calico.*"
$env:POD_NAMESPACE = 'kube-system'
$Env:KUBECONFIG=("c:\k\config")
# $Env:KUBECONFIG="$Env:KUBECONFIG;$HOME\.kube\config"

$KubernetesVersion = "1.20.6"
$kubernetesPath = "C:\k"
New-Item -ItemType Directory -Path $kubernetesPath -Force > $null

# switch to pulling down the bundle found at https://dl.k8s.io/v1.20.6/kubernetes-node-windows-amd64.tar.gz
Invoke-WebRequest -OutFile $kubernetesPath\kubelet.exe https://storage.googleapis.com/kubernetes-release/release/v$KubernetesVersion/bin/windows/amd64/kubelet.exe
Invoke-WebRequest -OutFile $kubernetesPath\kubectl.exe https://storage.googleapis.com/kubernetes-release/release/v$KubernetesVersion/bin/windows/amd64/kubectl.exe
Invoke-WebRequest -OutFile $kubernetesPath\kube-proxy.exe https://storage.googleapis.com/kubernetes-release/release/v$KubernetesVersion/bin/windows/amd64/kube-proxy.exe

New-Item -ItemType Directory -Path "C:\opt\cni\bin" -Force >$null
New-Item -ItemType Directory -Path "C:\etc\cni\net.d" -Force > $null

Invoke-WebRequest -UseBasicParsing https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-windows-amd64-v0.9.1.tgz -OutFile c:\opt\cni\bin\cni-plugins.tgz
cd c:\opt\cni\bin\ 
tar -xzf cni-plugins.tgz

Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/kubelet-config.yaml -OutFile c:\k\kubelet-config.yaml
