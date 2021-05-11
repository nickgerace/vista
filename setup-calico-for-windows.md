### Use the rke2 team's Calico windows install script instead of the upstream
```
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/install-calico-windows.ps1 -OutFile c:\install-calico-windows.ps1
powershell c:\install-calico-windows.ps1 -DownloadOnly yes -KubeVersion 1.20.6 -ServiceCidr "10.42.0.0/16" -DNSServerIPs 10.43.0.10
```

### Modify config.ps1 with your NODENAME
```
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/calico-config.ps1 -OutFile c:\CalicoWindows\config.ps1 -Force
Invoke-WebRequest https://raw.githubusercontent.com/nickgerace/vista/main/install-calico.ps1 -OutFile c:\CalicoWindows\install-calico.ps1 -Force

powershell c:\CalicoWindows\install-calico.ps1
```
