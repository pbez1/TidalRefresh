<#
Does DIFF backups of the specifed databases.
#>
function Backup-PSAllDiffs {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $SystemName
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [string] $GroupID = "1"
        ,
        [Parameter(Mandatory = $false)]
        [string] $ConfigServer = $ConfigurationServer
        ,
        [Parameter(Mandatory = $false)]
        [string] $ConfigDB = $ConfigurationDatabase
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    #Validate parameters
    if ('diff' -ne $RestoreType) {
        Write-Warning 'Backups are only implemented for the "diff" restore type.'
        return
        }

    # Get the list of databases we'll be working with.
    $sql = "select vt.dbname, vt.restore_to, vt.path_override, vt.dbname_pattern, vt.filepath from $TableSchema.v_tidal_all vt where vt.system_nm = '$SystemName' and vt.group_id = $GroupID and lower(vt.path_name) = '$($RestoreType.Trim().ToLower())'"
    $dbs = Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    # Loop through the database list, build the restore script fore each database and execute it.
    foreach ($db in $dbs) {
        if ($db.dbname_pattern) {
            # Replace the database tag (<dbname>) with the database name and the date tag (<date1>, <date2>) with the correct date and format.
            if ($($db.dbname_pattern).IndexOf('<date1>') -gt 0) {
                $dts = "{0:yyyy-MM-dd-HHmmss}" -f $(Get-Date)
                $db_file_name = ($db.dbname_pattern -replace "`<dbname`>", $db.dbname) -replace "`<date1`>", $dts
                }
            else {
                if ($($db.dbname_pattern).IndexOf('<date2>') -gt 0) {
                    $dts = "{0:yyyyMMddHHmmss}" -f $(Get-Date)
                    $db_file_name = ($db.dbname_pattern -replace "`<dbname`>", $db.dbname) -replace "`<date2`>", $dts
                    }
                else {
                    $db_file_name = ($db.dbname_pattern -replace "`<dbname`>", $db.dbname)
                    }
                }
            }
        else {
            $db_file_name = $db.dbname
            }
            
        # Replace the default backup file path with the overide path if one has been submitted, otherwise, keep the default path.
        if ('' -eq $db.path_override) {
            $full_backup_name = Join-Path -Path $db.filepath -ChildPath $db_file_name
            }
        else {
            # Override the default databaase backup location if an override has been specified.
            $full_backup_name = Join-Path -Path $db.path_override -ChildPath $db_file_name
            } 
    
        # Restore the specified database.
        $sql = Backup-PSSingleDB -TargetServer $db.restore_to -SystemName $SystemName -FolderPath $full_backup_name -Database $db.dbname -RestoreType $RestoreType.Trim().ToLower() -DBNamingPattern $db.dbname_pattern -ScriptOnly:$ScriptOnly

        $out_val = $sql + "`n`n"
        Write-Host $out_val
        }
    }
