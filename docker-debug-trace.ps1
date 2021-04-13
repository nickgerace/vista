function set_docker_debug {
    $tempConfig = @(get-content C:\ProgramData\Docker\config\daemon.json -ErrorAction SilentlyContinue)
    try {
        if ($tempConfig -match '"debug": true') {
            Write-Host "Debug is already enabled for Docker"
        } 
        if ([String]::IsNullOrWhiteSpace((Get-content C:\ProgramData\Docker\config\daemon.json -ErrorAction SilentlyContinue))) {
            New-Item -Path C:\ProgramData\Docker\config\daemon.json -value '{ "debug": true }'
            # set-content  -path C:\ProgramData\Docker\config\daemon.json -value '{ "debug": true }'
            if ($tempConfig -match '"debug": true') {
            restart-service docker 
            sleep 10
            }elseif ((get-service docker).Status -ne "Running"){
                sleep 20 
                if ((get-service docker).Status -ne "Running") {
                    Write-Error "Docker Service has not restarted successfully in 30 seconds"
                }   
            }
        }elseif ((Get-content C:\ProgramData\Docker\config\daemon.json -ErrorAction SilentlyContinue) -ne $Null) {
            if ($tempConfig -notmatch '"debug": true') {
                Write-Error "Docker daemon file C:\ProgramData\Docker\config\daemon.json is not empty"
                Write-Host "Please append the following line to the end of the daemon.json file" 
                Write-Host '"debug": true' 
                Write-Host "exiting..."
                throw
                }
            }
    }
    catch {
        Write-Host "An error occurred:"
        Write-Host $_
    }
}

function docker_start_trace {
    $rootDir = (docker info -f "{{.DockerRootDir}}")

    try {
        if ((get-service docker).Status -eq "Running") {
            Write-Host "Docker Service is currently running"
            Write-Host "Downloading Docker Signal executable"
            if (!(Test-Path c:\docker-signal.exe)){
                curl.exe -L https://github.com/moby/docker-signal/raw/master/docker-signal.exe -o c:\docker-signal.exe
            }
            Write-Host "Starting Docker Stack Trace"
            c:\docker-signal.exe --pid=$((get-process dockerd).Id)
            Write-Host "Docker Stack Trace has been completed"
            Write-Host "Gathering Docker Event logs and writing to C:\docker-logs.json"
            Get-WinEvent -ProviderName "docker" -MaxEvents 2500 -ErrorAction SilentlyContinue | ConvertTo-Json | Out-File c:\docker-trace.json
            Write-Host "Gathering Docker goroutine stack trace logs and moving to C:\"
            copy-item $rootDir\goroutine-stacks*.log C:\
            Write-Host "The goroutine stack trace logs can be found at" $(dir C:\goroutine-stacks*.log)
        }
        if ((get-service docker).Status -ne "Running") {
                Write-Warning "Docker Service is not currently running"
                Write-Host "Attempting to restart docker service"
                restart-service docker 
                sleep 10
                if ((get-service docker).Status -ne "Running"){
                    sleep 20 
                    if ((get-service docker).Status -ne "Running") {
                        Write-Error "Docker Service has not restarted successfully in 30 seconds"
                        Write-Host "Docker Stace Trace requires Docker to be running"
                        Write-Host "exiting..."
                        throw
                    }   
                }
                if ((get-service docker).Status -eq "Running") {
                    docker_start_trace
                }
            }
        }
        catch {
            Write-Host "An error occurred:"
            Write-Host $_        
        }
}
set_docker_debug
docker_start_trace
