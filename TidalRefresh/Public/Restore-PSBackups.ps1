<#
Collect the list of databases, backup netowrk locations as well as a list of all the latest backups.
Match them up and output the SQL statements to restore the databases in the database list.
#>
function Restore-PSBackups {
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
        [Parameter(Mandatory = $false )]
        [string] $ConfigServer = $ConfigurationServer
        ,
        [Parameter(Mandatory = $False)]
        [string] $ConfigDB = $ConfigurationDatabase
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    # Initialize some local variables.
    # This variable improves script readability, nothing more.
    $restore_type = $RestoreType.Trim().ToLower()

    # Get the list of databases we'll be working with.
    $sql = "select vt.dbname, vt.restore_to, vt.path_override, vt.dbname_pattern from $TableSchema.v_tidal_all vt where vt.system_nm = '$SystemName' and vt.group_id = $GroupID and lower(vt.path_name) = '$($restore_type)'"
    $dbs = Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    # Get the network locations where the backups are stored.
    $sql = "select distinct tp.filepath from $TableSchema.v_tidal_all tp where lower(tp.path_name) = '$restore_type' and system_nm = '$SystemName'"
    $tidal_path = (Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql).filepath

    # Get a list of the most recent full backups.  These are the *actual* path and file names of the databases to be restored.
    $latest_backups = @()
    foreach ($location in $tidal_path) {
        $latest_backups += Get-PSLatestBackups -FolderPath $location -RestoreType $restore_type -SystemName $SystemName
        }

    # Loop through the database list, build the restore script fore each database and execute it.
    foreach ($db in $dbs) {
        foreach ($backup in $latest_backups){
            $file_name = Split-Path -Path $backup -Leaf
            if ($restore_type -eq 'full') {
                if ($file_name.Substring(0, $file_name.IndexOf('_Full_')) -eq $($db.dbname)) {
                    $full_backup_name = $backup
                    break
                    }
                }
            else {
                # if ($file_name.Substring(0, $file_name.IndexOf('_refresh')) -eq $($db.dbname)) {
                if ($file_name.Substring(0, $file_name.IndexOf('_Diff_')) -eq $($db.dbname)) {
                    $full_backup_name = $backup
                    break
                    }
                }
            }
        
        # Get the proper values for "full" or "diff", whichever has been specified.
        $override = $db.path_override
        $backup_path = $full_backup_name
        $db_naming_pattern = $db.dbname_pattern

        # Override the default databaase backup location if an override has been specified.
        if ('' -ne $override) {
            $backup_path = $override
            } 
    
        # Restore the specified database
        $sql = Restore-PSSingleDB `
            -TargetServer $db.restore_to `
            -FolderPath $backup_path `
            -Database $($db.dbname) `
            -RestoreType $restore_type `
            -DBNamingPattern $db_naming_pattern `
            -ScriptOnly:$ScriptOnly

        if ($ScriptOnly) {
            $out_val = $sql + "`n`n"
            Write-Host $out_val
            }
        }
    }
