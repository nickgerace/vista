# TODO
# add cli arg for containerd log level
# add cli arg for custom output directory
# add checks for custom containerd config
# add parsing for containerd default location config.toml
# possibly add arg to custom location config.toml and parse it for req values
# add cli arg for custom containerd location/config
# start snapshot with containerd first
# prompt warning that containerd will restart and require user to type 'agree'

$containerdExe = "C:\Program Files\containerd\containerd.exe"

function containerd_log {
    # todo
    # add custom directory to copy containerd log file to
    $logTrace = "$containerdExe --log-level trace"
    $logDebug = "$containerdExe --log-level debug"
try {
    if ((Get-Service -Name containerd).Status -ne "Running") {
        restart-service containerd
        sleep 5
        if ((Get-Service -Name containerd).Status -eq "Running") {
            stop-service containerd
            if ((Get-Service -Name containerd).Status -eq "Stopped") {
                if (!(Get-Process -Name containerd).Exists) {
                    $logTrace
                }
        }
        sleep 10
        if ((Get-Service -Name containerd).Status -ne "Running") {
            Write-Error "The containerd service is not running"
            Write-Host "Attempt to restart containerd has not been successful"
            Write-Host "exiting..."
            throw
            }
        }
    }
    if ((Get-Service -Name containerd).Status -eq "Running") {
        stop-service containerd
        if ((Get-Service -Name containerd).Status -eq "Stopped") {
            containerd_log
           }
        }
    }
    catch {
        Write-Host $_
    }
}

function containerd_pprof {
$cdPprof = $containerdExe pprof
try {
    if ((Get-Service -Name containerd).Status -ne "Running") {
        restart-service containerd
        sleep 15
        if ((Get-Service -Name containerd).Status -ne "Running") {
            Write-Error "The containerd service is not running"
            Write-Host "Attempt to restart containerd has not been successful"
            Write-Host "exiting..."
            throw
        }
    }
    if ((Get-Service -Name containerd).Status -eq "Running") {
        $cdPprof
            }
        }
    # to-do: process pprofs 
    catch {
        Write-Host $_
    }
}

function reset_log_level {
    # todo
    # write a check to verify that containerd log level is no longer debug/trace
    try {
        if ((Get-Service -Name containerd).Status -ne "Running") {
            stop-service containerd
            sleep 5
            if ((Get-Process -Name containerd).Exists) {
                $cdPRocess = ((Get-Process -Name containerd).Id)
                stop-process --pid $cdPRocess
            }
            sleep 5
            if (!(Get-Process -Name containerd).Exists) {
                restart-service containerd
                sleep 10
                if ((Get-Service -Name containerd).Status -eq Running) {
                    Write-Host "containerd service has successfully restarted"
                if ((Get-Process -Name containerd).Exists) {
                    Write-Host "containerd process exists"
                    Write-Host "containerd log level has been reset to default"
                    Write-Host "exiting..."
                    }
                }
            }
        }
    }
    catch {
        Write-Host $_
    }
}

function get_logs {
    # todo
    # write check for stale log files already existing
    # find and copy containerd logs to c:\ root dir
    # create zip or tgz from log files
    # get event logs as well that would contain anything containerd or pprof related (application? containerd provider?)
    try {

    }
    catch {
        Write-Host $_
    }
}

