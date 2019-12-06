function startService{

    param($ServerName, $ServiceName)
     
    Invoke-Command -ScriptBlock{
        
        $ServiceStatus = (Get-Service $Using:ServiceName).Status
        $ServiceName = (Get-Service $Using:ServiceName).Name
        
        if(Compare-Object $ServiceStatus "Running"){
            Write-Host "$ServiceName is stopped, attempting to start"
            Start-Service $ServiceName -PassThru
        } else {
            Write-Host "$Using:ServiceName is $ServiceStatus"
        }

    } $ServerName | fl -Property PSComputerName,Name,DisplayName,Status
}

function stopService{

    param($ServerName, $ServiceName)
     
    Invoke-Command -ScriptBlock{
        stop-Service $Using:ServiceName -PassThru
    } $ServerName | fl -Property PSComputerName,Name,DisplayName,Status
}

function startService{

    param($ServerName, $ServiceName)
     
    Invoke-Command -ScriptBlock{
        
        $ServiceStatus = (Get-Service $Using:ServiceName).Status
        $ServiceName = (Get-Service $Using:ServiceName).Name
        
        if(Compare-Object $ServiceStatus "Running"){
            Write-Host "$ServiceName is stopped, attempting to start"
            Start-Service $ServiceName -PassThru
        } else {
            Write-Host "$Using:ServiceName is $ServiceStatus"
        }

    } $ServerName | fl -Property PSComputerName,Name,DisplayName,Status
}

function stopService{

    param($ServerName, $ServiceName)
     
    Invoke-Command -ScriptBlock{
        stop-Service $Using:ServiceName -PassThru
    } $ServerName | fl -Property PSComputerName,Name,DisplayName,Status
}

function cpuUsage{

    param($ServerName)

    Invoke-Command -ScriptBlock{

                $p = @(
                @{n="Process Name    "; e={$_."Name"}; align="left"}
                @{n="CPU Usage    "; e={$_."Value"}; align="left"}
            )
	
        $arrayUsage = New-Object System.Collections.Generic.List[System.Object]
        $arrayProcessBig = New-Object System.Collections.Generic.List[System.Object]
        $arrayProcessSmall = New-Object System.Collections.Generic.List[System.Object]
        $j = 5

#Data collection

        for($i = 0; $i -lt $j; $i++){
            $progress = (100/$j)*$i
            Write-Progress -Activity "Gathering CPU Load data to determine average usage" -Status "$progress%" -PercentComplete $progress;

            $topConsuming = Get-WmiObject -class Win32_PerfFormattedData_PerfProc_Process | Select-Object IDProcess, Name, PercentProcessorTime
            
            $processor = (Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select Average).Average
            $arrayUsage.Add($processor)

            $arrayProcessBig.Add($topConsuming)
        }
       
#Data representation

        foreach($processBig in $arrayProcessBig){
            $arrayProcessSmall += $processBig
        }

        $processNames = $arrayProcessSmall.Name | Select -Unique
        $processHash = @{}
        $processNames | foreach{$processHash[$_] = 0}
        
        foreach($process in $arrayProcessSmall){
            $processHash[$process.Name] += $process.PercentProcessorTime
        }

        $processHash.Remove("_Total")
        $processHash.Remove("Idle")
        
        foreach($process in @($processHash.keys)){
            $processHash[$process] = [math]::Round($processHash[$process]/$j, 1)
        }
        
        Write-Host "`n`nCPU average usage:" ("{0}{1}" -f ([math]::Round(($arrayUsage | Measure-Object -Average).average,1)), "%") "`n"
        Write-Host "Top 5 CPU consuming processes:"
        #($topConsuming | Sort CPU -Descending | Select -First 3 | ft -Property $p -AutoSize | out-string -stream).Replace(" ", "_")
        #$topConsuming | Sort CPU -Descending | Select -First 3 | ft -AutoSize

        ($processHash.GetEnumerator() | Sort "Value" -Descending | Select -First 5 | ft -Property $p -AutoSize | out-string -stream).Replace(" ", "_")

    } $ServerName
}
    

function getText{

    param($ServerName, $Location)

    Invoke-Command -ScriptBlock{
        Get-ItemProperty $Using:Location | Select-Object -Property LastWriteTime
        Write-Host "`nCONTENT:`n"
        Get-Content -Path $Using:Location
    } $ServerName
}


function runCMD{

    param($ServerName, $Location)

    Invoke-Command -ScriptBlock{
        $Using:Location | cmd
    }$ServerName
} 


function checkOVC{

    param($ServerName)

    $status = Invoke-Command -ScriptBlock{
                  "ovc -status" | cmd
              }$ServerName 

    if($status | Select-String -Pattern "Stopped"){
        Invoke-Command -ScriptBlock{
            Write-Warning "`n`nIt appears that some agents are stopped, running ovc -restart`n`n"
            "ovc -restart & ovc -status" | cmd
        }$ServerName
    } else {
        $status
    }
}  


function simba{

    param($ServerName, $Instance=$Null)

    if($Instance){
        $Instance = $Instance.ToUpper()
        Invoke-Command -ScriptBlock{
            "C:\Appli\Simba\Monitor\ScapSimbaMonitor.exe | find `"$Using:Instance`"" | cmd
        }$ServerName
    } else {
        Invoke-Command -ScriptBlock{
            "C:\Appli\Simba\Monitor\ScapSimbaMonitor.exe" | cmd
        }$ServerName
    }
}


function checkDisk{

    param($ServerName)

    Invoke-Command -ScriptBlock{
        $disksPS = @(Get-PSDrive -PSProvider FileSystem)
        $disksWMI = @(Get-WmiObject -Class Win32_logicaldisk -Filter "DriveType = '3'")
        $disksPS = @($disksPS | Where-Object -property used -ne 0)
        $tables = @()
        $count = 0

        For($i = 0; $i -lt $disksPS.Length; $i++){
            $spFree = [math]::Round($disksPS[$i].free/1GB,1)
            $spUsed = [math]::Round($disksPS[$i].used/1GB,1)
            $table = New-Object PSObject -property @{
                "Drive" = $disksPS[$i].Name;
                "Drive Name" = $disksWMI[$i].VolumeName;
                "Space Total (GB)" = $spUsed + $spFree;
                "Space Used (GB)" = $spUsed;
                "Space Free (GB)" = $spFree;
                "Space Used (%)" = [math]::Round(-100*$spFree/($spFree + $spUsed) + 100, 1);
            }
            $tables += $table
        }
        $p = `
        @(
            @{n="Drive    "; e={$_.Drive}; align="left"}
            @{n="Drive Name    "; e={$_."Drive Name"}; align="left"}
            @{n="Space Total (GB)    "; e={$_."Space Total (GB)"}; align="left"}
            @{n="Space Used (GB)    "; e={$_."Space Used (GB)"}; align="left"}
            @{n="Space Free (GB)    "; e={$_."Space Free (GB)"}; align="left"}
            @{n="Space Used (%)    "; e={$_."Space Used (%)"}; align="left"}
                      
        )
        $tables | Format-Table "Drive","Drive Name","Space Total (GB)","Space Free (GB)", "Space Used (GB)","Space Used (%)" -AutoSize
        ($tables | Format-Table -Property $p | out-string -stream).Replace(" ","_")
    } $ServerName
}

    

function getText{

    param($ServerName, $Location)

    Invoke-Command -ScriptBlock{
        Get-ItemProperty $Using:Location | Select-Object -Property LastWriteTime
        Write-Host "`nCONTENT:`n"
        Get-Content -Path $Using:Location
    } $ServerName
}


function runCMD{

    param($ServerName, $Location)

    Invoke-Command -ScriptBlock{
        $Using:Location | cmd
    }$ServerName
} 


function checkOVC{

    param($ServerName)

    $status = Invoke-Command -ScriptBlock{
                  "ovc -status" | cmd
              }$ServerName 

    if($status | Select-String -Pattern "Stopped"){
        Invoke-Command -ScriptBlock{
            Write-Warning "`n`nIt appears that some agents are stopped, running ovc -restart`n`n"
            "ovc -restart & ovc -status" | cmd
        }$ServerName
    } else {
        $status
    }
}  


function simba{

    param($ServerName, $Instance=$Null)

    if($Instance){
        $Instance = $Instance.ToUpper()
        Invoke-Command -ScriptBlock{
            "C:\Appli\Simba\Monitor\ScapSimbaMonitor.exe | find `"$Using:Instance`"" | cmd
        }$ServerName
    } else {
        Invoke-Command -ScriptBlock{
            "C:\Appli\Simba\Monitor\ScapSimbaMonitor.exe" | cmd
        }$ServerName
    }
}


function checkDisk{

    param($ServerName)

    Invoke-Command -ScriptBlock{
        $disksPS = @(Get-PSDrive -PSProvider FileSystem)
        $disksWMI = @(Get-WmiObject -Class Win32_logicaldisk -Filter "DriveType = '3'")
        try{
            $disksPS = @($disksPS | Where-Object -property "Used" -ne 0)
        }
        catch{
        }
        $tables = @()
        $count = 0

        For($i = 0; $i -lt $disksPS.Length; $i++){
            $spFree = [math]::Round($disksPS[$i].free/1GB,1)
            $spUsed = [math]::Round($disksPS[$i].used/1GB,1)
            $table = New-Object PSObject -property @{
                "Drive" = $disksPS[$i].Name;
                "Drive Name" = $disksWMI[$i].VolumeName;
                "Space Total (GB)" = $spUsed + $spFree;
                "Space Used (GB)" = $spUsed;
                "Space Free (GB)" = $spFree;
                "Space Used (%)" = [math]::Round(-100*$spFree/($spFree + $spUsed) + 100, 1);
            }
            $tables += $table
        }
        $p = `
        @(
            @{n="Drive    "; e={$_.Drive}; align="left"}
            @{n="Drive Name    "; e={$_."Drive Name"}; align="left"}
            @{n="Space Total (GB)    "; e={$_."Space Total (GB)"}; align="left"}
            @{n="Space Used (GB)    "; e={$_."Space Used (GB)"}; align="left"}
            @{n="Space Free (GB)    "; e={$_."Space Free (GB)"}; align="left"}
            @{n="Space Used (%)    "; e={$_."Space Used (%)"}; align="left"}
                      
        )
        $tables | Format-Table "Drive","Drive Name","Space Total (GB)","Space Free (GB)", "Space Used (GB)","Space Used (%)" -AutoSize
        try{
            ($tables | Format-Table -Property $p -AutoSize | out-string -stream).Replace(" ","_")
        }
        catch{
            ($tables | Format-Table -Property $p -AutoSize | out-string -stream) -replace (" ", "_")
        }
    } $ServerName
}
