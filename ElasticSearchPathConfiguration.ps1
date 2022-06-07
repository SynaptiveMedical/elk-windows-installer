param(
    [string]$ConfigFilePath = "C:\Elk\elasticsearch\config\elasticsearch.yml",
    [string]$DataPath = "C:/Elk/elasticsearch/data",
    [string]$LogsPath = "C:/Elk/elasticsearch/logs",
    [string]$RepoPath = "C:/Elk/elasticsearch/AllSnapshots",
    [string]$NetworkHost = "0.0.0.0"
)

function Update-ElasticSearchConfiguration
{
    Param(
        [string]$ConfigFilePath,
        [string]$DataPath,
        [string]$LogsPath,
        [string]$RepoPath,
        [string]$NetworkHost
    )

    function Set-ConfigurationEntry {
        Param (
            [string[]][ref]$FileLines,
            [string]$MatchRegEx,
            [string]$Value
        )

        $ConfigUpdate = $false

        for($i = 0; $i -lt $FileLines.Count; $i++) {

            $Line = $FileLines[$i]
            
            if ($Line -match $MatchRegEx) {
            
                Write-Host "Updating entry $Value"
                $FileLines[$i] = $Value
                $ConfigUpdate = $true
                break
            }
        }

        if (-not $ConfigUpdate) {

            Write-Host "Appending new entry $Value"
            # The array is of fixed size, so just append text to the last line
            $FileLines[$FileLines.Count -1] += "`n$Value"
        }
    }

    Write-Host $MyInvocation.MyCommand

    if (-Not $ConfigFilePath -Or -Not (Test-Path $ConfigFilePath -PathType Leaf)) {
        Write-Host "Failed to locate elasticsearch configuration file: $ConfigFilePath." 
        throw "Failed to locate elasticsearch configuration file: $ConfigFilePath." 
    }
    
    [string[]]$FileLines = (Get-Content $ConfigFilePath)

    $DataPathConfigEntry = "path.data: $DataPath" -replace '\\','/'
    $LogsPathConfigEntry = "path.logs: $LogsPath" -replace '\\','/'
    $RepoPathConfigEntry = "path.repo: $RepoPath" -replace '\\','/'
    $NetworkHost = "network.host: $NetworkHost" -replace '\\','/'
    
    Set-ConfigurationEntry -FileLines ([ref]$FileLines) -MatchRegEx "^\s*path\.data\s*:\s*" -Value $DataPathConfigEntry
    Set-ConfigurationEntry -FileLines ([ref]$FileLines) -MatchRegEx "^\s*path\.logs\s*:\s*" -Value $LogsPathConfigEntry
    Set-ConfigurationEntry -FileLines ([ref]$FileLines) -MatchRegEx "^\s*path\.repo\s*:\s*" -Value $RepoPathConfigEntry
    Set-ConfigurationEntry -FileLines ([ref]$FileLines) -MatchRegEx "^\s*network\.host\s*:\s*" -Value $NetworkHost

    Set-Content $ConfigFilePath $FileLines

    Write-Host "$($MyInvocation.MyCommand) done."
}

try {
    Update-ElasticSearchConfiguration -ConfigFilePath $ConfigFilePath -DataPath $DataPath -LogsPath $LogsPath -RepoPath $RepoPath -NetworkHost $NetworkHost
    exit 0
}
Catch {
    Write-Host $_.Exception.Message
    exit 1
}