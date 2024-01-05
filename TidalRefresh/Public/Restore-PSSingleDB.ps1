<#
Generates the SQL statement to restore a single database and optionally executes it.
#>
function Restore-PSSingleDB {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $TargetServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $Database
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [string] $FolderPath
        ,
        [Parameter(Mandatory = $false)]
        [string] $DBNamingPattern
        ,
        [Parameter(Mandatory = $false)]
        [String] $EncryptionKey = "m#3rY@SP"
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

#region Validate
    # Validate and initialize
    if (!$FolderPath) {
        # This section is old and probably not needed any longer.  It remains here because it demonstrates important
        # logic that may be useful in the future.
        if ($DBNamingPattern) {
            # Replace the database tag with the database name and the date tag with the correct date and format.
            if ($DBNamingPattern.IndexOf('<date1>') -gt 0) {
                $dts = "{0:yyyy-MM-dd-HHmmss}" -f $(Get-Date)
                $dbname = ($DBNamingPattern -replace "`<dbname`>", $Database) -replace "`<date1`>", $dts
                }
            else {
                if ($DBNamingPattern.IndexOf('<date2>') -gt 0) {
                    $dts = "{0:yyyyMMddHHmmss}" -f $(Get-Date)
                    $dbname = ($DBNamingPattern -replace "`<dbname`>", $Database) -replace "`<date2`>", $dts
                    }
                }
            }
        else {
            $dbname = $Database
            }

        $FullBackupName = Join-Path -Path $FolderPath -ChildPath $dbname
        }
    else {
        $FullBackupName = $FolderPath
        }
    
#endregion Validate
    Write-Verbose "Starting restore of: $Database, from path: $FullBackupName"

    # Get a list of the database file locations from the target SQL Server.  These are the locations that will 
    # be used in the MOVE clause of the restore command.
    $sql = Get-PSSQLStatement -CommandType 'Get File Locations'
    $file_group = Invoke-Sqlcmd @sql_parms -ServerInstance $TargetServer -Database 'master' -Query $sql

    # Create the "Move" section of the script since there may be a variable number of database files
    $move_section = ''
    foreach ($file in $file_group) {
        $move_section += "                @with = 'MOVE ''$($file.name)'' TO ''$($file.physical_name)''',`n"
        }

    # Create the executable SQL statement to restore the database.  The SQL statement will be different depending
    # on the type of restore being done; whether FULL or DIFF.
    if ($RestoreType -eq 'full') {
        $sql = Get-PSSQLStatement -CommandType 'Restore Full'
        }
    else {
        if ('diff' -eq $RestoreType.ToLower()) {
            $sql = Get-PSSQLStatement -CommandType 'Restore Diff'
            }
        }

    # If the user only wants the SQL script, return it.  Otherwise, Execute the restore script.
    if ($ScriptOnly) {
        $sql
        }
    # else {
    #     # Invoke-Sqlcmd @sql_parms -ServerInstance = $TargetServer -Database 'master' -Query = $sql
    #     }
    }
