# OsbornePro LLC. Update Elasticsearch Instance on Windows Server
#
# IMPORTANT: After running I realized I need to carry over the password databases and such so this is not 100% yet
#
# For this to work you will need to modify lines 8, 21, 22, 27, 28, 33, 34, 63, 64
# Baseed on how you set things up you may or may not need to modify lines 14, 19, 23, 25, 31, 44, 45, 74, 75, 87

$CurrentVersion = (.'C:\Program Files\elasticsearch\bin\elasticsearch.bat' --version 2> $Null).Split(' ')[1].Replace(',','')
$Response = Invoke-WebRequest -Method GET -Uri "https://github.com/elastic/elasticsearch/releases" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36 Edg/92.0.902.84"
$NewestVersion = ($Response.Links | Where-Object { ($_.InnerText -like "v*.*.*") -and ($_.InnerText -notlike "*alpha*") -and ($_.InnerText -notlike "*beta*") } | Sort-Object -Property InnerText -Descending | Select-Object -First 1 -ExpandProperty InnerText).Replace("v","")
If ($CurrentVersion -ne $NewestVersion) {

    Write-Output "[*] Stopping Elasticsearch services"
    Stop-Service -Name "elasticsearch-service-x64","kibana","winlogbeat" -Force

    Write-Output "[*] Building links using version info for Elasticsearch, Kibana, and Winlogbeat"
    $ELKHashTable = @{}
    $ELKHashTable.Elasticsearch = @()
    $ELKHashTable.Elasticsearch += "elasticsearch"
    $ELKHashTable.Elasticsearch += "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$Version-windows-x86_64.zip"
    $ELKHashTable.Elasticsearch += "C:\Program Files\elasticsearch"
    $ELKHashTable.Elasticsearch += "C:\Program Files\elasticsearch.bak\config\elasticsearch.yml"
    $ELKHashTable.Elasticsearch += "elasticsearch-service-x64"
    $ELKHashTable.Kibana = @()
    $ELKHashTable.Kibana += "kibana"
    $ELKHashTable.Kibana += "https://artifacts.elastic.co/downloads/kibana/kibana-$Version-windows-x86_64.zip"
    $ELKHashTable.Kibana += "C:\Program Files\kibana"
    $ELKHashTable.Kibana += "C:\Program Files\kibana.bak\config\kibana.yml"
    $ELKHashTable.Kibana += "kibana"
    $ELKHashTable.Winlogbeat = @()
    $ELKHashTable.Winlogbeat += "winlogbeat"
    $ELKHashTable.Winlogbeat += "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-$Version-windows-x86_64.zip"
    $ELKHashTable.Winlogbeat += "C:\Program Files\winlogbeat"
    $ELKHashTable.Winlogbeat += "C:\Program Files\winlogbeat.bak\winlogbeat.yml"
    $ELKHashTable.Winlogbeat += "winlogbeat"

    ForEach ($Elk in $ELKHashTable.Keys) {

        $Program = $ELKHashTable.$Elk.Item(0)
        $Uri = $ELKHashTable.$Elk.Item(1)
        $Path = $ELKHashTable.$Elk.Item(2)
        $YMLFile = $ELKHashTable.$Elk.Item(3)
        $Service = $ELKHashTable.$Elk.Item(4)
        $BackupPath = "$Path.bak"
        $OutFile = "$env:USERPROFILE\Downloads\$Program.zip"

        Write-Output "[*] Backing up old configuration for $Program"
        If ((Test-Path -Path $BackupPath) -and (Test-Path -Path $Path)) {

            Remove-Item -Path "$Path.bak" -Force

        }  # End If

        Write-Output "[*] Backing up current $Program version"
        Move-Item -Path $Path -Destination $BackupPath -Recurse -Force -ErrorAction Stop

        Write-Output "[*] Downloading the $Program zip file"
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -Method GET -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36 Edg/92.0.902.84" -ContentType "application/zip"

        Write-Output "[*] Extracting the $Program zip file"
        Expand-Archive -Path $OutFile -DestinationPath $Path.Replace("$Program","")
        Rename-Item -Path (Get-ChildItem -Path "$Path-$Version*" -Directory -Force | Select-Object -ExpandProperty FullName -First 1 | Out-String).Trim() -NewName $Path

        If (Test-Path -Path $Path) {

            Write-Output "[*] Deleting the downloaded and extracted zip file"
            Remove-Item -Path "$env:USERPROFILE\Downloads\$Program.zip" -Force

        }  # End If

        If ($Program -ne "winlogbeat") {

            Write-Output "[*] Placing SSL Certificates into new Directory"
            Copy-Item -Path "$BackupPath\config\cert.crt" -Destination "$Path\config\cert.crt" 
            Copy-Item -Path "$BackupPath\config\key.key" -Destination "$Path\config\key.key"

        }  # End If

        Write-Output "[*] Backing up the $Program.yml default file"
        Move-Item -Path $YMLFile.Replace(".bak","") -Destination "$YMLFile.orig" -Force

        Write-Output "[*] Updating YML configuration file for $Program.yml"
        Copy-Item -Path $YMLFile -Destination $YMLFile.Replace(".bak","") -Force

    }  # End ForEach

    Start-Service -Name "elasticsearch-service-x64","kibana","winlogbeat"

}  # End If
