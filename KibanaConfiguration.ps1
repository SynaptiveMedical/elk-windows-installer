param(
    [string]$ConfigFilePath = 'C:\Elk\kibana\config\kibana.yml',
    [string]$ServerHost = "0.0.0.0"
)

function Update-KibanaConfiguration
{
    Param(
        [string]$ConfigFilePath,
        [string]$ServerHost
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

    $ServerHost = "server.host: $ServerHost" -replace '\\','/'
    
    Set-ConfigurationEntry -FileLines ([ref]$FileLines) -MatchRegEx "^\s*server\.host\s*:\s*" -Value $ServerHost

    Set-Content $ConfigFilePath $FileLines

    Write-Host "$($MyInvocation.MyCommand) done."
}

try {
    Update-KibanaConfiguration -ConfigFilePath $ConfigFilePath -ServerHost $ServerHost
    exit 0
}
Catch {
    Write-Host $_.Exception.Message
    exit 1
}