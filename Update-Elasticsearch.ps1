# OsbornePro LLC. Update Elasticsearch Instance on Windows Server
#
# IMPORTANT: After running I realized I need to carry over the password databases and such so this is not 100% yet
#
# For this to work you will need to modify lines 8, 21, 22, 27, 28, 33, 34, 63, 64 (basically your file locations)
# Baseed on how you set things up you may or may not need to modify lines 14, 19, 23, 25, 31, 44, 45, 74, 75, 87
Write-Output "[8] Comparing current version to available version"
$CurrentVersion = (.'C:\elk\elasticsearch\bin\elasticsearch.bat' --version 2> $Null).Split(' ')[1].Replace(',','')
$Response = Invoke-WebRequest -Method GET -Uri "https://github.com/elastic/elasticsearch/releases" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36 Edg/92.0.902.84"
$NewestVersion = (($Response.Links | Where-Object { ($_.InnerText -like "v*.*.*") -and ($_.InnerText -notlike "*alpha*") -and ($_.InnerText -notlike "*beta*") } | Sort-Object -Property InnerText -Descending | Select-Object -First 1 -ExpandProperty InnerText).Replace("v","")).Replace(" ","")
$Services = @()

If ($CurrentVersion -ne $NewestVersion) {

    Write-Output "[*] Building links using version info for Elasticsearch, Kibana, and Winlogbeat"
    $ELKHashTable = @{}
    $ELKHashTable.ElasticAgent = @()
    $ELKHashTable.ElasticAgent += "Elastic Agent"
    $ELKHashTable.ElasticAgent += "https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-$($NewestVersion)-windows-x86_64.zip"
    $ELKHashTable.ElasticAgent += "C:\elk\elastic-agent"
    $ELKHashTable.ElasticAgent += "C:\elk\elastic-agent.bak\elastic-agent.yml"
    $ELKHashTable.ElasticAgent += "Elastic Agent"
    $ELKHashTable.Kibana = @()
    $ELKHashTable.Kibana += "kibana"
    $ELKHashTable.Kibana += "https://artifacts.elastic.co/downloads/kibana/kibana-$($NewestVersion)-windows-x86_64.zip"
    $ELKHashTable.Kibana += "C:\elk\kibana"
    $ELKHashTable.Kibana += "C:\elk\kibana.bak\config\kibana.yml"
    $ELKHashTable.Kibana += "kibana"
    $ELKHashTable.Elasticsearch = @()
    $ELKHashTable.Elasticsearch += "elasticsearch"
    $ELKHashTable.Elasticsearch += "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$($NewestVersion)-windows-x86_64.zip"
    $ELKHashTable.Elasticsearch += "C:\elk\elasticsearch"
    $ELKHashTable.Elasticsearch += "C:\elk\elasticsearch.bak\config\elasticsearch.yml"
    $ELKHashTable.Elasticsearch += "elasticsearch-service-x64"

    ForEach ($Elk in $ELKHashTable.Keys) {

        $Program = $ELKHashTable.$Elk.Item(0)
        $Services += $Program
        $Uri = $ELKHashTable.$Elk.Item(1)
        $Path = $ELKHashTable.$Elk.Item(2)
        $YMLFile = $ELKHashTable.$Elk.Item(3)
        $Service = $ELKHashTable.$Elk.Item(4)
        $BackupPath = "$Path.bak"
        $OutFile = "$env:USERPROFILE\Downloads\$Program.zip"

        Write-Output "[*] Stopping Elasticsearch services"
        Stop-Service -Name $Service -Force


        Write-Output "[*] Backing up old configuration for $Program"
        If ((Test-Path -Path $BackupPath) -and (Test-Path -Path $Path)) {
    
            Remove-Item -Path $BackupPath -Recurse -Force
    
        }  # End If 

        Write-Output "[*] Backing up current $Program version"
        Move-Item -Path $Path -Destination $BackupPath -Force -ErrorAction Inquire

        Write-Output "[*] Downloading the $Program zip file"
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -Method GET -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36 Edg/92.0.902.84" -ContentType "application/zip"

        Write-Output "[*] Extracting the $Program zip file"
        If ($Program -ne "Elastic Agent") {

            Expand-Archive -Path $OutFile -DestinationPath $Path.Replace("$Program","")
            Rename-Item -Path (Get-ChildItem -Path "$Path-$Version*" -Directory -Force | Select-Object -ExpandProperty FullName -First 1 | Out-String).Trim() -NewName $Path.Split("\")[-1]

            Write-Output "[*] Placing SSL Certificates into new Directories"
            Copy-Item -Path "$BackupPath\config\cert.crt" -Destination "$Path\config\cert.crt" 
            Copy-Item -Path "$BackupPath\config\key.key" -Destination "$Path\config\key.key"

        }  # End If
        ElseIf ($Program -eq "Elastic Agent") {

            Expand-Archive -Path $OutFile -DestinationPath $Path.Replace("elastic-agent","")
            Rename-Item -Path (Get-ChildItem -Path "$Path-$Version*" -Directory -Force | Select-Object -ExpandProperty FullName -First 1 | Out-String).Trim() -NewName $Path.Split("\")[-1]

            Write-Output "[*] Placing trusted CA Certificate file into new Directory"
            Copy-Item -Path "$BackupPath\ca.pem" -Destination "$Path\ca.pem"

        }  # End ElseIf
        Else {

            Write-Error "[x] Program name $Program was not recognized"

        }  # End If


        If (Test-Path -Path $Path) {

            Write-Output "[*] Deleting the downloaded and extracted zip file"
            Remove-Item -Path "$env:USERPROFILE\Downloads\$Program.zip" -Force

        }  # End If
        Else {

            Write-Error "[x] The directory $Path could not be found. This indicates the Zip file failed to extract or directory failed to rename or it was deleted manually already."

        }  # End Else 
        
        If ($Program -eq "elasticsearch") {

            Write-Output "[*] Rebuilding the elastic search keystore"
            Add-Content -Path $YMLFile.Replace(".bak","") -Value "xpack.security.enabled: true" -Force
            Start-Service -Name $Service

            Write-Output "[*] Execution will continue as soon as port 9200 is up an active"
            Do {

                $PortOpen = (Get-NetTcpConnection -State Listen | Where-Object -Property LocalPort -eq 9200)[0].LocalPort
                Start-Sleep -Seconds 3

            } While ($PortOpen -ne 9200)

            Write-Output "[*] Enter your documented passwords for each account to set the password of that account"
            Start-Process -FilePath "cmd" -ArgumentList "/k $Path\bin\elasticsearch-setup-passwords.bat interactive" -WindowStyle Normal
            Pause
            Stop-Service -Name $Service -Force

        }  # End If

        Write-Output "[*] Backing up the $Program.yml default file"
        Move-Item -Path $YMLFile.Replace(".bak","") -Destination "$YMLFile.orig" -Force

        Write-Output "[*] Updating YML configuration file for $Program.yml"
        Copy-Item -Path $YMLFile -Destination $YMLFile.Replace(".bak","") -Force

    }  # End ForEach

    Read-Host -Prompt "Press ENTER to resume starting all ELK services back up"
    Write-Output "[*] Starting Services back up"
    Start-Service -Name $Services
    Get-Service -Name $Services

}  # End If
