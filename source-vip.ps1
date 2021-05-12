$sourceVipJson = [io.Path]::Combine($Global:BaseDir,  "sourceVip.json")
$sourceVipRequest = [io.Path]::Combine($Global:BaseDir,  "sourceVipRequest.json")

$hnsNetwork = Get-HnsNetwork | ? Name -EQ Calico
$subnet = $hnsNetwork.Subnets[0].AddressPrefix

$ipamConfig = @"
    {"cniVersion": "0.3.1", "name": "Calico", "ipam":{"type":"host-local","ranges":[[{"subnet":"$subnet"}]],"dataDir":"/var/lib/cni/networks"}}
"@
$ipamConfig | Out-File sourceVipRequest.json

pushd
$env:CNI_COMMAND="ADD"
$env:CNI_CONTAINERID="dummy"
$env:CNI_NETNS="dummy"
$env:CNI_IFNAME="dummy"
$env:CNI_PATH="c:\opt\cni\bin"
cd $env:CNI_PATH
Get-Content sourceVipRequest.json | .\host-local.exe | Out-File sourceVip.json
$sourceVipJSONData = Get-Content sourceVip.json | ConvertFrom-Json

Remove-Item env:CNI_COMMAND
Remove-Item env:CNI_CONTAINERID
Remove-Item env:CNI_NETNS
Remove-Item env:CNI_IFNAME
Remove-Item env:CNI_PATH
popd

return $sourceVipJSONData.ips[0].address.Split("/")[0]
