# OsbornePro LLC. Update Elasticsearch Instance on Windows Server
#
# Script I am working on to automatically update Elasticsearch on a Windows Server
#
# For this to work you will need to modify lines 8, 21, 22, 27, 28, 33, 34, 63, 64
# Baseed on how you set things up you may or may not need to modify lines 14, 19, 23, 25, 31, 74

$CurrentVersion = (.'C:\elk\elasticsearch\bin\elasticsearch.bat' --version 2> $Null).Split(' ')[1].Replace(',','')
#$Response = Invoke-WebRequest -Method GET -Uri "https://www.elastic.co/downloads/elasticsearch" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36 Edg/92.0.902.84"
#$NewVersion = $Response.ParsedHtml NOT FINISHED
$Version = Read-Host -Prompt "What is the latest version of Elasticsearch available. EXAMPLE: 7.14.0"

Write-Output "[*] Stopping Elasticsearch services"
Stop-Service -Name "elasticsearch-service-x64","kibana","winlogbeat" -Force

Write-Output "[*] Building links using version info for Elasticsearch, Kibana, and Winlogbeat"
$ELKHashTable = @{}
$ELKHashTable.Elasticsearch = @()
$ELKHashTable.Elasticsearch += "elasticsearch"
$ELKHashTable.Elasticsearch += "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$Version-windows-x86_64.zip"
$ELKHashTable.Elasticsearch += "C:\Program Files\elasticsearch"
$ELKHashTable.Elasticsearch += "C:\Program Files\elasticsearch\config\elasticsearch.yml"
$ELKHashTable.Elasticsearch += "elasticsearch-service-x64"
$ELKHashTable.Kibana = @()
$ELKHashTable.Kibana += "kibana"
$ELKHashTable.Kibana += "https://artifacts.elastic.co/downloads/kibana/kibana-$Version-windows-x86_64.zip"
$ELKHashTable.Kibana += "C:\Program Files\kibana"
$ELKHashTable.Kibana += "C:\Program Files\kibana\config\kibana.yml"
$ELKHashTable.Kibana += "kibana"
$ELKHashTable.Winlogbeat = @()
$ELKHashTable.Winlogbeat += "winlogbeat"
$ELKHashTable.Winlogbeat += "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-$Version-windows-x86_64.zip"
$ELKHashTable.Winlogbeat += "C:\Program Files\winlogbeat"
$ELKHashTable.Winlogbeat += "C:\Program Files\winlogbeat\winlogbeat.yml"
$ELKHashTable.Winlogbeat += "winlogbeat"

ForEach ($Elk in $ELKHashTable.Keys) {

    $Program = $ELKHashTable.$Elk.Item(0)
    $Uri = $ELKHashTable.$Elk.Item(1)
    $Path = $ELKHashTable.$Elk.Item(2)
    $YMLFile = $ELKHashTable.$Elk.Item(3)
    $Service = $ELKHashTable.$Elk.Item(4)
    $BackupPath = "$Path.bak"

    Write-Output "[*] Backing up old configuration for $Program"
    If ((Test-Path -Path "$Path.bak") -and (Test-Path -Path $Path)) {

        Remove-Item -Path "$Path.bak" -Force

    }  # End If

    Write-Output "[*] "
    Move-Item -Path $Path -Destination "$Path.bak" -Recurse -Force -ErrorAction Stop

    Write-Output "[*] Downloading the $Program zip file"
    Invoke-WebRequest -Uri $Uri -OutFile "$env:USERPROFILE\Downloads\$Program.zip" -Method GET -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36 Edg/92.0.902.84" -ContentType "application/zip"

    Write-Output "[*] Extracting the $Program zip file"
    Expand-Archive -Path "$env:USERPROFILE\Downloads\$FileName.zip" -DestinationPath $Path

    Write-Output "[*] Placing SSL Certificates into new Directory"
    Copy-Item -Path "$BackupPath\config\cert.crt" -Destination "$Path\config\cert.crt"
    Copy-Item -Path "$BackupPath\config\key.key" -Destination "$Path\config\key.key"

    Write-Output "[*] Backing up the $Program.yml default file"
    Move-Item -Path $YMLFile -Destination "$YMLFile.orig" -Force

    Write-Output "[*] Updating YML configuration file for $Program.yml"
    Copy-Item -Path "$BackupPath\config\$Program.yml" -Destination $YMLFile -Force

}  # End ForEach

Start-Service -Name "elasticsearch-service-x64","kibana","winlogbeat"
