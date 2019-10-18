function startService{

    param($ServerName, $ServiceName)
     
    Invoke-Command -ScriptBlock{
        start-Service $Using:ServiceName -PassThru
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
    $i = 0
    $j = 10

    Invoke-Command -ScriptBlock{
	
        $array = New-Object System.Collections.Generic.List[System.Object]
        $i = 0
        $j = 10

        while($i -lt $j){

            $progress = (100/$j)*$i
            Write-Progress -Activity "Gathering CPU Load data to determine average usage" -Status "$progress%" -PercentComplete $progress;
            
            $processor = (Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select Average).Average
            $array.Add($processor)

            $i++
            Start-Sleep -s .5
        }

        Write-Host $topConsuming
        Write-Host "`nCPU average usage during last 5 seconds:" ("{0}{1}" -f ($array | Measure-Object -Average).average, "%")

    } $ServerName
}
    

function getText{

    param($ServerName, $Location)

    Invoke-Command -ScriptBlock{
        Get-ItemProperty $Using:Location | Select LastWriteTime
        Get-Content -Path $Using:Location
    } $ServerName
}


function runCMD{

    param($ServerName, $Location)

    Invoke-Command -ScriptBlock{
        $Using:Location | cmd
    }$ServerName
} 


function ovc{

    param($ServerName, $Parameter)

    Invoke-Command -ScriptBlock{
        "ovc -$Using:Parameter" | cmd
    }$ServerName
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

    $new_session = New-PSSession -ComputerName $ServerName

    $with_separator = Invoke-Command -Session $new_session -ScriptBlock{
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
    }
}
