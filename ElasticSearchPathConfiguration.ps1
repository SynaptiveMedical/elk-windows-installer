param(
    [string]$ConfigFilePath = "C:\Elk\elasticsearch\config\elasticsearch.yml",
    [string]$DataPath = "C:/Elk/elasticsearch/data",
    [string]$LogsPath = "C:/Elk/elasticsearch/logs",
    [string]$RepoPath = "C:/Elk/elasticsearch/AllSnapshots"
)

function Update-ElasticSearchConfiguration
{
    Param(
        [string]$ConfigFilePath,
        [string]$DataPath,
        [string]$LogsPath,
        [string]$RepoPath
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

    Write-Host $ExecutionContext.InvokeCommand

    if (-Not $ConfigFilePath -Or -Not (Test-Path $ConfigFilePath -PathType Leaf)) {
        Write-Host "Failed to locate elasticsearch configuration file: $ConfigFilePath." 
        throw "Failed to locate elasticsearch configuration file: $ConfigFilePath." 
    }
    
    [string[]]$FileLines = (Get-Content $ConfigFilePath)

    $DataPathConfigEntry = "path.data: $DataPath" -replace '\\','/'
    $LogsPathConfigEntry = "path.logs: $LogsPath" -replace '\\','/'
    $RepoPathConfigEntry = "path.repo: $RepoPath" -replace '\\','/'

    Set-ConfigurationEntry -FileLines ([ref]$FileLines) -MatchRegEx "^\s*path\.data\s*:\s*" -Value $DataPathConfigEntry
    Set-ConfigurationEntry -FileLines ([ref]$FileLines) -MatchRegEx "^\s*path\.logs\s*:\s*" -Value $LogsPathConfigEntry
    Set-ConfigurationEntry -FileLines ([ref]$FileLines) -MatchRegEx "^\s*path\.repo\s*:\s*" -Value $RepoPathConfigEntry

    Set-Content $ConfigFilePath $FileLines

	Restart-Service elasticsearch-service-x64 -Force -ErrorAction SilentlyContinue -ErrorVariable RestartError

    if($RestartError) {
        throw $RestartError
    }

    Write-Host "$($ExecutionContext.InvokeCommand) done."
}

try {
    Update-ElasticSearchConfiguration -ConfigFilePath $ConfigFilePath -DataPath $DataPath -LogsPath $LogsPath -RepoPath $RepoPath
    exit 0
}
Catch {
    Write-Host $_.Exception.Message
    exit 1
}