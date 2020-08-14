<#
    .SYNOPSIS
      Grab hash/signature information from a source folder. Run recursively across any folder or drive
    
    .NOTES
      Ben Shorehill: ben.shorehill@insentragroup.com
#>

Function Find-Folders {
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = "C:\"
    $browse.ShowNewFolderButton = $false
    $browse.Description = "Select the root directory to scan"

    $loop = $true
    while ($loop) {
        if ($browse.ShowDialog() -eq "OK") {
            $loop = $false
        }
        else {
            $res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if ($res -eq "Cancel") {
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()
} 

$SourcePath = Find-Folders
Write-Host $SourcePath


$ApplicationArray = @()
Get-ChildItem -Recurse -Include *.exe -Path $SourcePath  | ForEach-Object { [pscustomobject]$File = .\sigcheck.exe -r -c -nobanner -h $_ | ConvertFrom-Csv

    if ($File.Verified -eq "Unsigned") {
        $ApplicationEntry = [PSCustomObject]@{
      
            'PROGRAM'         = $_
            'COMMAND-LINE'    = ""
            'ID'              = ""
            'GROUP-ID'        = ""
            'FILE-HASH'       = $file.SHA256
            'PUBLISHER'       = ""
            'SIGNATURE-FLAGS' = ""
            'REPUTATION'      = ""
            'RULE-NAME'       = ""
            'COMMENT'         = $File.Product + " " + $File.'Product version'
        }
    }
    else {
        $ApplicationEntry = [PSCustomObject]@{
            'PROGRAM'         = $_
            'COMMAND-LINE'    = ""
            'ID'              = ""
            'GROUP-ID'        = ""
            'FILE-HASH'       = ""
            'PUBLISHER'       = $file.Publisher
            'SIGNATURE-FLAGS' = ""
            'REPUTATION'      = ""
            'RULE-NAME'       = ""
            'COMMENT'         = $File.Product + " " + $File.'Product version'
        }
    }

    $ApplicationArray += $ApplicationEntry
}


Function Save-File([string] $initialDirectory ) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

    $OpenFileDialog = New-Object -TypeName System.Windows.Forms.SaveFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV files (*.csv)| *.csv"
    $OpenFileDialog.Title = "Save your output file"
    $OpenFileDialog.ShowDialog() |  Out-Null

    return $OpenFileDialog.filename
} 

# Export the array to a CSV file
$outCSV = Save-File ~\
$ApplicationArray | Export-Csv $outCSV -NoTypeInformation
