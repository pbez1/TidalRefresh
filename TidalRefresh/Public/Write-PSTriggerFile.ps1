<#
Given a $TriggerName (and optional $CopyToName) will create the specified trigger file (or copy an existing trigger file).
#>
function Write-PSTriggerFile {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $SystemName
        ,
        [Parameter(Mandatory = $false)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [int] $GroupID = 1
        ,
        [Parameter(Mandatory = $true)]
        [string] $TriggerName
        ,
        [Parameter(Mandatory = $false)]
        [string] $ConfigServer = $ConfigurationServer 
        ,
        [Parameter(Mandatory = $false)]
        [string] $ConfigDB = $ConfigurationDatabase
        ,
        [Parameter(Mandatory = $false)]
        [string] $CopyToName
        )

    $sql = "select filepath, filename, file_content from tidal_path where path_name = '$TriggerName'"
    $trigger_data = Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql
    $trigger_file = Join-Path -Path $($trigger_data.filepath) -ChildPath $($trigger_data.filename)

    # If the caller has supplied a $CopyToName, this is a copy rather than a new file creation.
    if ($CopyToName) {
        $sql = "select filepath, filename, file_content from tidal_path where path_name = '$CopyToName'"
        $copy_to_data = Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql
        $copy_to_file = Join-Path -Path $($copy_to_data.filepath) -ChildPath $($copy_to_data.filename)

        Write-Verbose "Copying file: $trigger_file, to: $copy_to_file"
        Copy-Item -Path $trigger_file -Destination $copy_to_file -Force
        }
    else {
        # This is a simple file creation task.
        if (Test-Path $trigger_file -PathType leaf) {
            Remove-Item $trigger_file
            }

        Write-Verbose "Creating trigger file: $trigger_file"

        # New-Item $trigger_file -ItemType File -Value $($trigger_file.file_content)
        $trigger_data.file_content | Out-File $trigger_file
        }
    }
