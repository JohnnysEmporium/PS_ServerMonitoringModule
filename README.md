# PS_ServerMonitoringModule
Set of functions for Windows Powershell that help remotely manage Windows Servers

## Getting Started
### Installation

- Download and extract [this repository](https://github.com/JohnyHCL/PS_ServerMonitoringModule/archive/master.zip).
- Run Powershell.
- Execute `$Env:PSModulePath` in order to display Powershell Modules location.
- This command may return more than one location, the one we're interested in is not empty (meaning: lots of folders inside).
- Paste *ServerMonitoring* folder inside.
- In Powershell execute `Import-Module ServerMonitoring` and you're ready to go.


## Documentation

Arguments in **[ ]** brackets are optional 

#### Starting/Stopping a service

`startService "ServerName" "ServiceDisplayName"`

#### Dsiaply CPU usage

`cpuUsage "ServerName"`

#### Display *.txt, *.log, etc.

`getText "ServerName" "LocationOfFile"`

#### Execute custom CMD command

`runCMD "ServerName" "Command"`

#### Check SCAP Simba Instances

`simba "ServerName" ["InstanceName"]` 

#### Check free disk space

`checkDisk "ServerName" ["DiskLetter"]`


