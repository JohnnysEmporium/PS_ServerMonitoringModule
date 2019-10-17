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

    param($ServerName, $Instance)

    $Instance = $Instance.ToUpper()

    Invoke-Command -ScriptBlock{
        "C:\Appli\Simba\Monitor\ScapSimbaMonitor.exe | find `"$Using:Instance`"" | cmd
    }$ServerName
}


function checkDisk{

    param($ServerName, $Disk = $null)
  
    Invoke-Command -ScriptBlock{
        $disk = $Using:Disk
        $drive = Get-PSDrive $Using:Disk
        
        if($Using:Disk){
            $disk = $disk.ToUpper()
            $spaceLeft = [math]::abs((($drive.Free/($drive.Used+$drive.Free))*100-100))
            $spaceLeft = [math]::Round($spaceLeft,1)
            Write-Host ("Disk {0}:\ is {1}% full" -f $disk, $spaceLeft)
        }
    }$ServerName
}
