# Import-Module SqlServer

function Write-PSTriggerFile {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [int] $GroupID = 1
        ,
        [Parameter(Mandatory = $true)]
        [string] $TriggerName
        ,
        [Parameter(Mandatory = $false)]
        [string] $CopyToName
        )

    $sql = "select filepath, filename, file_content from tidal_path where path_type = '$TriggerName'"
    $trigger_data = Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql
    $trigger_file = Join-Path -Path $($trigger_data.filepath) -ChildPath $($trigger_data.filename)

    # If the caller has supplied a $CopyToName, this is a copy rather than a new file creation.
    if ($CopyToName) {
        $sql = "select filepath, filename, file_content from tidal_path where path_type = '$TriggerName'"
        $copy_to_data = Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql
        $copy_to_file = Join-Path -Path $($copy_to_data.filepath) -ChildPath $($copy_to_data.filename)

        Write-Verbose "Copying file: $trigger_file, to: $copy_to_file"
        #Copy-Item -Path $trigger_file -Destination $copy_to_file -Force
        }
    else {
        # This is a simple file creation task.
        if (Test-Path $trigger_file -PathType leaf) {
            Remove-Item $trigger_file
            }

        Write-Verbose "Creating trigger file: $trigger_file"

        # New-Item $trigger_file -ItemType File -Value $($trigger_file.file_content)
        #$trigger_data.file_content | Out-File $trigger_file
        }
    }

function Disconnect-PSConnections {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [int] $GroupID = 1
        ,
        [Parameter(Mandatory = $false)]
        [string] $Revision
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    # Get a list of the databases we intend to process from the tidal_main table.  
    # Include the server that contains the database that will be overwritten so we can extract the users list.
    Write-Verbose 'Getting the list of databases to process from the "tidal_main" table.'
    $sql = "select restore_to + '.' + dbname database_name from $ConfigDB.dbo.tidal_main where restore_type = '$RestoreType' and group_id = $GroupID"
    $Databases = Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    foreach ($db in $Databases) {
        $src_server = $($db.database_name).split('.')[0]
        $dbname = $($db.database_name).split('.')[1]
        
        Write-Verbose "Disconnecting Connections to: $dbname"
        $sql = @"
            ALTER DATABASE $dbname
            SET OFFLINE WITH ROLLBACK IMMEDIATE

            ALTER DATABASE $dbname
            SET ONLINE
"@
        if ($ScriptOnly) {
            Write-Host $sql
            }
        else {
            # Invoke-Sqlcmd -ServerInstance $src_server -Database 'master' -Query $sql | Out-Null
            }
        }
    }

function Get-LatestBackups {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $FolderPath                    #= "\\firqa\sqlbackups5\sdc-prodqadb"
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType 
        )

    Write-Verbose "Getting the list of most recent backups for path: $FolderPath."

    if ($RestoreType.ToLower() -eq 'full') {$extension = '.bak'}
    else {
        if ($RestoreType.ToLower() -eq 'diff') {$extension = '.diff'}
        else {
            throw 'Error in Get-LatestBackups: -RestoreType parameter must be either "full" or "diff"'
            }
        }

    $all_files = (Get-ChildItem -Path $FolderPath -File `
        | Sort-Object -Property LastWriteTime -Descending) `
        | Where-Object {$_.Extension -eq $extension}
    
    $file_paths = @()
    foreach ($file in $all_files) {
        $file_paths += Join-Path -Path $file.DirectoryName -ChildPath $file.Name
        }

    $file_paths
    }

function Get-SQLStatement {
    [cmdletbinding()]

    param (
        [Parameter(Mandatory = $true)]
        [string] $CommandType
        )

#-----------------------------------------------------------------------------------------------------
#  PLACE SQL SECTIONS BELOW THIS BANNER
#-----------------------------------------------------------------------------------------------------

    # Get the commands to add the users back after the restore.
    if ('Get Users Perms' -eq $CommandType.ToLower()) {
        $sql = @"
            select
                '$CommandType' cmd_type,
                '$dbname' dbname,
                'CREATE USER [' + RTrim(u.name) + '] FOR LOGIN [' + RTrim(l.name)collate database_default + ']' as 'command',
                '$Revision' revision
            from
                [$dbname].dbo.sysusers u
                inner join [$dbname].sys.syslogins l on u.sid = l.sid
            where
                u.islogin = 1
                and u.hasdbaccess = 1
                and u.name not in ('dbo', 'guest', 'audit')
                and u.name not like '##%'
"@
        }

    # Get the commands to add users back into their respective database roles.
    if ('Get Users Roles' -eq $CommandType.ToLower()) {
        $sql = @"
            select
                '$CommandType' cmd_type,
                '$dbname' dbname,
                'EXEC sp_addrolemember ''''' + RTrim(r.name) + ''''',''''' + RTrim(Coalesce(u.name, l.name)collate database_default) + '''''' as 'command',
                '$Revision' revision
            from
                [$dbname].dbo.sysusers u
                inner join [$dbname].dbo.sysmembers m on u.uid = m.memberuid
                inner join [$dbname].dbo.sysusers r on m.groupuid = r.uid
                inner join master.dbo.syslogins l on u.sid = l.sid
            where
                r.issqlrole = 1
                and u.name not in ('dbo', 'guest', 'audit')
                and r.name like '%'
"@
        }

    # Get the commands to drop users from their databases.
    if ('Drop Users' -eq $CommandType.ToLower()) {
        $sql = @"
            select
                '$CommandType' cmd_type,
                '$dbname' dbname,
                'DROP USER [' + RTrim(u.name) + ']' as command,
                '$Revision' revision
            from [$dbname].dbo.sysusers u
            where
                u.islogin = 1
                and u.hasdbaccess = 1
                and u.name not in ('dbo', 'guest', 'audit')
                and u.name not like '##%'
            order by u.name
"@
        }

    if ('Restore Full' -eq $CommandType.ToLower()) {
        $sql = @"
            alter database $Database
            set offline with rollback immediate;
            
            alter database $Database
            set online;
            `
            exec dbo.xp_restore_database 
                @database = '$Database',
                @logging = 1,
                @filename = '$FullBackupName',
                @filenumber = 1,`n
"@                  + $move_section + @"
                @with = 'replace',
                @with = 'STATS=10',
                @with = 'norecovery',
                @EncryptionKey = '$EncryptionKey'
"@
        }

    if ('Restore Diff' -eq $CommandType.ToLower()) {
        $sql = @"
            exec dbo.xp_restore_database 
                @database = '$Database',
                @logging = 1,
                @filename = '$FullBackupName',
                @filenumber = 1,`n
"@              + $move_section + @"
                @with = 'REPLACE',
                @with = 'STATS=10',
                @with = 'recovery',
                @EncryptionKey = 'm#3rY@SP'
"@
        }

    if ('Backup Diff' -eq $CommandType.ToLower()) {
        $sql = @"
            exec dbo.xp_backup_database
                @database = '$Database',
                @filename= = '$FullBackupName',
                @with = 'DIFFERENTIAL',
                @init = 1,
                @encryptionkey = 'm#3rY@SP'
"@
        }

    if ('Get File Locations' -eq $CommandType.ToLower()) {
        $sql = @"
            select mf.name, mf.physical_name, mf.type, mf.state_desc 
            from master.sys.master_files mf inner join master.sys.databases d on d.database_id = mf.database_id
            where d.name = '$Database'
"@
        }

    if ('Run User Perms' -eq $CommandType.ToLower()) {
        $sql = "select tu.command from $ConfigDB.dbo.tidal_user tu where tu.cmd_type = 'Get Users' and tu.dbname = '$dbname'"
        }
    
    if ('Run User Roles' -eq $CommandType.ToLower()) {
        $sql = "select tu.command from $ConfigDB.dbo.tidal_user tu where tu.cmd_type = 'Get Roles' and tu.dbname = '$dbname'"
        }
            
    if ('Run Drop Users' -eq $CommandType.ToLower()) {
        $sql = "select tu.command from $ConfigDB.dbo.tidal_user tu where tu.cmd_type = 'Drop Users' and tu.dbname = '$dbname'"
        }
                    
                                #---->  Code goes above this line.

    $sql
    }

function Invoke-PSPersistCommands {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [int] $GroupID = 1
        ,
        [Parameter(Mandatory = $true)]
        [string] $CommandType
        ,
        [Parameter(Mandatory = $false)]
        [string] $Revision
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    $dt = Get-Date
    if (!$Revision) {$revision = "{0:yyyy-MM-dd HH:mm:ss}" -f $dt}

    # Get a list of the databases we intend to process from the tidal_main table.  
    # Include the server that contains the database that will be overwritten so we can extract the users list.
    Write-Verbose 'Getting the list of databases to process from the "tidal_main" table.'
    $sql = "select restore_to + '.' + dbname database_name from $ConfigDB.dbo.tidal_main where restore_type = '$RestoreType' and group_id = $GroupID"
    $Databases = Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    foreach ($db in $Databases) {
        $src_server = $($db.database_name).split('.')[0]
        $dbname = $($db.database_name).split('.')[1]

        # Execute the SQL that retrieves the commands to store in tidal_users.
        Write-Verbose "Saving commands for database: $dbname"
        $sql = Get-SQLStatement -CommandType $CommandType
        $result_set = Invoke-Sqlcmd -ServerInstance $src_server -Database 'master' -Query $sql
        # Write-Host $sql

        $insert_stmt = ""
        $insert_stmt = "insert into dbo.tidal_user (cmd_type, dbname, command, revision) values `n"

        Write-Verbose "    Saving commands for $dbname"
        $max_i = 400
        $i = 1
        foreach ($row in $result_set) { 
            $insert_stmt += "('{0}', '{1}', '{2}', '{3:s}'),`n" -f $($row.cmd_type), $($row.dbname), $($row.command), $($row.revision)

            # We need to bundle the "Values" clause to insert groups of $max_i rows.  This requires Invoke_DbaQuery to be invoked once per $max_i rows instead of for every row.
            if ($i -ge $max_i) {
                # Strip the trailing comma and CR.
                $insert_stmt = $($insert_stmt.Trim()).Substring(0, $insert_stmt.Length - 2)

                if ($ScriptOnly) {
                    Write-Output $insert_stmt
                    }
                else {
                    Write-Verbose "        Writing a batch for $dbname"
                    Invoke-Sqlcmd `
                        -ServerInstance $ConfigServer `
                        -Database $ConfigDB `
                        -QueryTimeout 0 `
                        -Query $insert_stmt                           
                    }
                
                $i = 1
                $insert_stmt = ""
                $insert_stmt = "insert into dbo.tidal_user (cmd_type, dbname, command, revision) values `n"
                }
            else {
                $i++
                }
            }        

        # We may not have #max_i rows to insert especially at the end.  Handle them here.
        # Strip the trailing comma and CR.
        $insert_stmt = $($insert_stmt.Trim()).Substring(0, $insert_stmt.Length - 2)

        if ($ScriptOnly) {
            Write-Output $insert_stmt
            }
        else {
            Write-Verbose "        Writing final batch for $dbname"
            Invoke-Sqlcmd `
                -ServerInstance $ConfigServer `
                -Database $ConfigDB `
                -QueryTimeout 0 `
                -Query $insert_stmt
            }
        }
    }

function Invoke-PSExecuteCommands {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [int] $GroupID = 1
        ,
        [Parameter(Mandatory = $true)]
        [string] $CommandType
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )
 
    $dt = Get-Date
    if (!$Revision) {$revision = "{0:yyyy-MM-dd HH:mm:ss}" -f $dt}

    # Get a list of the databases we intend to process from the tidal_main table.  
    # Include the server that contains the database that will be overwritten so we can extract the users list.
    Write-Verbose 'Getting the list of databases to process from the "tidal_main" table.'
    $sql = "select restore_to + '.' + dbname database_name from $ConfigDB.dbo.tidal_main where restore_type = '$RestoreType' and group_id = $GroupID"
    $Databases = Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    $cmd_stmt = ""

    foreach ($db in $Databases) {
        $src_server = $($db.database_name).split('.')[0]
        $dbname = $($db.database_name).split('.')[1]

        # Execute the SQL that retrieves the commands to store in tidal_users.
        $sql = Get-SQLStatement -CommandType $CommandType
        $result_set = Invoke-Sqlcmd -ServerInstance $src_server -Database $dbname -Query $sql
        # Write-Host $sql
    
        $cmd_stmt = ""

        Write-Verbose "    Retrieving commands for $dbname"
        $max_i = 400
        $i = 1
        foreach ($row in $result_set) { 
            $cmd_stmt += "{0}`n" -f $($row.command)

            # We need to bundle the "Values" clause to insert groups of $max_i rows.  This requires Invoke_DbaQuery to be invoked once per $max_i rows instead of for every row.
            if ($i -ge $max_i) {
                # Strip the trailing comma and CR.
                $cmd_stmt = $($cmd_stmt.Trim()).Substring(0, $cmd_stmt.Length - 2)

                if ($ScriptOnly) {
                    Write-Output $cmd_stmt
                    }
                else {
                    Write-Verbose "        Executing a batch for $dbname"
                    # Invoke-Sqlcmd `
                    #     -ServerInstance $ConfigServer `
                    #     -Database $ConfigDB `
                    #     -QueryTimeout 0 `
                    #     -Query $cmd_stmt                           
                    }
                
                $i = 1
                $cmd_stmt = ""
                $cmd_stmt = "{0}`n" -f $($row.command)
                }
            else {
                $i++
                }
            }        

        # We may not have #max_i rows to insert especially at the end.  Handle them here.
        # Strip the trailing comma and CR.
        # $cmd_stmt = $($cmd_stmt.Trim()).Substring(0, $cmd_stmt.Length - 2)

        if ($ScriptOnly) {
            Write-Output "Database: $dbname"
            Write-Output "$cmd_stmt"
            }
        else {
            Write-Verbose "        Executing final batch for $dbname"
            # Invoke-Sqlcmd `
            #     -ServerInstance $ConfigServer `
            #     -Database $ConfigDB `
            #     -QueryTimeout 0 `
            #     -Query $cmd_stmt
            }
        }
    }

function Start-PreProcess {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [int] $GroupID = 1
        ,
        [Parameter(Mandatory = $false)]
        [string] $Group = "1"
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    # Delete all the rows from the tidal_user table in preparation for this batch.
    Write-Verbose 'Deleting all rows in the "tidal_user" table.'
    $sql = "delete $ConfigDB.dbo.tidal_user"
    Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql | Out-Null
        
#-----------------------------------------------------------------------------------------------------
#  PRE-PROCESS - FULL SECTION
#-----------------------------------------------------------------------------------------------------
    if ('full' -eq $RestoreType.ToLower()) {
#---->  Put any FULL restore post process tasks between the two arrows.

        # Get the commands to add the users back after the restore.
        Invoke-PSPersistCommands @parms -CommandType 'Get Users Perms' -ScriptOnly:$ScriptOnly
        Invoke-PSPersistCommands @parms -CommandType 'Get Users Roles' -ScriptOnly:$ScriptOnly

        # Kill existing connections to the databases.
        Disconnect-PSConnections @parms -ScriptOnly:$ScriptOnly

#---->
        }

#-----------------------------------------------------------------------------------------------------
#  PRE-PROCESS - DIFF SECTION
#-----------------------------------------------------------------------------------------------------
    else {
        # There are currently no PreProcess steps for DIFF restores.

#-----------------------------------------------------------------------------------------------------
#  PRE-PROCESS - ERROR SECTION
#-----------------------------------------------------------------------------------------------------
        if ('diff' -ne $RestoreType.ToLower()) {
            throw "You must supply a valid restore type.  Valid restore types are currently: DIFF and FULL."        
            }
        }
    }

function Start-PostProcess {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [int] $GroupID = 1
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

#-----------------------------------------------------------------------------------------------------
#  POST-PROCESS - DIFF SECTION
#-----------------------------------------------------------------------------------------------------

    if ('diff' -eq $RestoreType.ToLower()) {
#---->  Put any DIFF restore post process tasks between the two arrows.

        Write-Verbose "Post-Processing started."

        # Invoke-PSPersistCommands @parms -CommandType 'Drop Users' -ScriptOnly:$ScriptOnly
        Invoke-PSExecuteCommands @parms -CommandType 'Drop Users' -ScriptOnly:$ScriptOnly
        # Write-Verbose "Executing: exec dbo.AASP_PROV_NOT_FOUND_REFRESH"
        # # Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query 'exec dbo.AASP_PROV_NOT_FOUND_REFRESH'
        # Write-Verbose "Executing: update [dbo].[Token] SET [TokenValue] = 'BOGUS'"
        # # Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query "update [dbo].[Token] SET [TokenValue] = 'BOGUS'"
        # Write-Verbose "Executing: execute dbo.sp_ManageUsers 'HPXR', 0"
        # # Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query "execute dbo.sp_ManageUsers 'HPXR', 0"
        # Write-Verbose "Executing: update dbo.SYSTEM_PARAMETER set PARAMETER_VALUE = 'Y' where PARAMETER_NAME = 'START_LOAD'"
        # # Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query "update dbo.SYSTEM_PARAMETER set PARAMETER_VALUE = 'Y' where PARAMETER_NAME = 'START_LOAD'"
        # Write-Verbose "Creating trigger file: Refresh Complete"
        # # Write-PSTriggerFile @parms -TriggerName 'Refresh Complete'
        # Write-Verbose "Copying trigger file from NoGo.txt to Go.txt"
        # # Write-PSTriggerFile @parms -TriggerName 'Infraqa From' -CopyToName 'Infraqa To'
        
#---->
}
    else {
#-----------------------------------------------------------------------------------------------------
#  POST-PROCESS - FULL SECTION
#-----------------------------------------------------------------------------------------------------
#---->  Put any FULL restore post process tasks between the two arrows.

        # There are currently no Post-Process steps for FULL restores.

#---->

#-----------------------------------------------------------------------------------------------------
#  POST-PROCESS - ERROR SECTION
#-----------------------------------------------------------------------------------------------------
        if ('full' -ne $RestoreType.ToLower()) {
            throw "You must supply a valid restore type.  Valid restore types are currently: DIFF and FULL."        
            }
        }
    }
            
function Backup-PSSingleDB {
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
        [string] $FullBackupName
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
    if ($DBNamingPattern) {
        # Replace the database tag with the database name and the date tag with the date.
        $dts = "{0:yyyy-MM-dd-HHmmss}" -f $(Get-Date)
        $dbname = ($DBNamingPattern -replace "`<dbname`>", $Database) -replace "`<date`>", $dts
        }
    else {
        $dbname = $Database
        }

    if (!$FullBackupName) {
        if (!$FolderPath) {
            throw "You must supply either a -FullBackup name (backup folder and file name) or a -FolderPath (to be prepended to -Database).  Process aborted."
            }
        else {
            $FullBackupName = Join-Path -Path $FolderPath -ChildPath $dbname
            }
        }
#endregion Validate
    Write-Verbose "Starting differential backup of: $Database"

    # Create the executable SQL statement to restore the database.  The SQL statement will be different depending
    # on the type of restore being done; whether FULL or DIFF.
    $sql = Get-SQLStatement -CommandType 'Backup Diff'

    # If the user only wants the SQL script, return it.  Otherwise, Execute the restore script.
    if ($ScriptOnly) {
        $sql
        }
    # else {
    #     # Invoke-Sqlcmd -ServerInstance = $TargetServer -Database 'master' -Query = $sql
    #     }
    }

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
        [string] $FullBackupName
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
    if ($DBNamingPattern) {
        # Replace the database tag with the database name and the date tag with the date.
        $dts = "{0:yyyy-MM-dd-HHmmss}" -f $(Get-Date)
        $dbname = ($DBNamingPattern -replace "`<dbname`>", $Database) -replace "`<date`>", $dts
        }
    else {
        $dbname = $Database
        }

    if (!$FullBackupName) {
        if (!$FolderPath) {
            throw "You must supply either a -FullBackup name (backup folder and file name) or a -FolderPath (to be prepended to -Database).  Process aborted."
            }
        else {
            $FullBackupName = Join-Path -Path $FolderPath -ChildPath $dbname
            }
        }
#endregion Validate
    Write-Verbose "Starting restore of: $Database"

    # Get a list of the database file locations from the target SQL Server.  These are the locations that will 
    # be used in the MOVE clause of the restore command.
    $sql = Get-SQLStatement -CommandType 'Get File Locations'
    $file_group = Invoke-Sqlcmd -ServerInstance $TargetServer -Database 'master' -Query $sql

    # Create the "Move" section of the script since there may be a variable number of database files
    $move_section = ''
    foreach ($file in $file_group) {
        $move_section += "                @with = 'MOVE ''$($file.name)'' TO ''$($file.physical_name)''',`n"
        }

    # Create the executable SQL statement to restore the database.  The SQL statement will be different depending
    # on the type of restore being done; whether FULL or DIFF.
    if ($RestoreType -eq 'full') {
        $sql = Get-SQLStatement -CommandType 'Restore Full'
        }
    else {
        if ($RestoreType.ToLower() -eq 'diff') {
            $sql = Get-SQLStatement -CommandType 'Restore Diff'
            }
        }

    # If the user only wants the SQL script, return it.  Otherwise, Execute the restore script.
    if ($ScriptOnly) {
        $sql
        }
    # else {
    #     # Invoke-Sqlcmd -ServerInstance = $TargetServer -Database 'master' -Query = $sql
    #     }
    }

function Backup-PSAllDiffs {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [string] $GroupID = "1"
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    # Get the database information we'll be working with.
    $sql = "select vt.restore_type, vt.restore_to, vt.dbname, vt.filepath_override, vt.actual_filepath, vt.dbname_pattern from dbo.v_tidal vt where group_id = $GroupID and lower(vt.restore_type) = '$($RestoreType.Trim().ToLower())'"
    $dbs = Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    # Get network share locations of the backup files we'll be restoring.
    $sql = "select tp.filepath from dbo.tidal_path tp where lower(tp.path_type) = '$($RestoreType.Trim().ToLower())'"
    $tidal_path = Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    # Get a list of the most recent full backups.  We're going to get the *actual* file names of the databases to be restored.
    $latest_backups = @()
    foreach ($location in $tidal_path) {
        $latest_backups += Get-LatestBackups -FolderPath $($location.filepath) -RestoreType $RestoreType.Trim().ToLower()
        }

    # Loop through the database list, build the restore script fore each database and execute it.
    foreach ($db in $dbs) {
        if ($db.dbname_pattern) {
            # Replace the database tag with the database name and the date tag with the date.
            $dts = "{0:yyyy-MM-dd-HHmmss}" -f $(Get-Date)
            $dbname = ($db.dbname_pattern -replace "`<dbname`>", $db.dbname) -replace "`<date`>", $dts
            }
        else {
            $dbname = $Database
            }

        $full_backup_name = Join-Path -Path $location.filepath -ChildPath $dbname

            # Override the restore_to server if a value for $TargetServer has been suppled.`
        if (!$db.filepath_override) {
            $restore_to = $($db.filepath_override)} else {
                $restore_to = $($db.restore_to)}
    
        # Restore the specified database
        $sql = Backup-PSSingleDB -TargetServer $restore_to -Database $($db.dbname) -FullBackupName $full_backup_name -RestoreType $RestoreType.Trim().ToLower() -ScriptOnly:$ScriptOnly

        $out_val = $sql + "`n`n"
        Write-Host $out_val
        }
    }

function Restore-PSBackups {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [string] $GroupID = "1"
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    # Get the list of databases we'll be working with.
    $sql = "select vt.restore_type, vt.restore_to, vt.dbname, vt.filepath_override, vt.actual_filepath, vt.dbname_pattern from dbo.v_tidal vt where group_id = $GroupID and lower(vt.restore_type) = '$($RestoreType.Trim().ToLower())'"
    $dbs = Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    # Get the network locations where the backups are stored.
    $sql = "select tp.filepath from dbo.tidal_path tp where lower(tp.path_type) = '$($RestoreType.Trim().ToLower())'"
    $tidal_path = Invoke-Sqlcmd -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    # Get a list of the most recent full backups.  These are the *actual* path and file names of the databases to be restored.
    $latest_backups = @()
    foreach ($location in $tidal_path) {
        $latest_backups += Get-LatestBackups -FolderPath $($location.filepath) -RestoreType $RestoreType.Trim().ToLower()
        }

    # Loop through the database list, build the restore script fore each database and execute it.
    foreach ($db in $dbs) {
        foreach ($backup in $latest_backups){
            $file_name = Split-Path -Path $backup -Leaf
            if ($RestoreType.Trim().ToLower() -eq 'full') {
                if ($file_name.Substring(0, $file_name.IndexOf('_Full_')) -eq $($db.dbname)) {
                    $full_backup_name = $backup
                    }
                }
            else {
                if ($file_name.Substring(0, $file_name.IndexOf('_refresh')) -eq $($db.dbname)) {
                    $full_backup_name = $backup
                    }
                }
            }
        
        # Override the restore_to server if a value for $TargetServer has been suppled.`
        if (!$db.filepath_override) {
            $restore_to = $($db.filepath_override)} else {
                $restore_to = $($db.restore_to)}
    
        # Restore the specified database
        $sql = Restore-PSSingleDB -TargetServer $restore_to -Database $($db.dbname) -FullBackupName $full_backup_name -RestoreType $RestoreType.Trim().ToLower() -ScriptOnly:$ScriptOnly

        $out_val = $sql + "`n`n"
        Write-Host $out_val
        }
    }

function Invoke-DiffRestore {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [string] $GroupID = "1"
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    $parms.RestoreType = 'diff'

    # Start-PreProcess @parms -ScriptOnly:$ScriptOnly 
    # Backup-PSAllDiffs @parms -ScriptOnly:$ScriptOnly
    # Write-PSTriggerFile @parms -TriggerName 'Tidal Go Trigger'
    Restore-PSBackups @parms -ScriptOnly:$ScriptOnly
    # Start-PostProcess @parms -ScriptOnly:$ScriptOnly
    }

function Invoke-FullRestore {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [string] $GroupID = "1"
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    $parms.RestoreType = 'full'

    # Start-PreProcess @parms -ScriptOnly:$ScriptOnly 
    Restore-PSBackups @parms -ScriptOnly:$ScriptOnly
    # Start-PostProcess @parms -ScriptOnly:$ScriptOnly
    }
    
function Start-Restore {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $ConfigServer
        ,
        [Parameter(Mandatory = $true)]
        [string] $ConfigDB
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [string] $GroupID = "1"
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    # Set script wide Verbose behavior
    if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {$VerbosePreference = 'Continue'} else {$VerbosePreference = 'SilentlyContinue'}

    if ('full' -eq $RestoreType.ToLower()) {
        Invoke-FullRestore @parms -ScriptOnly:$ScriptOnly
        }
    else {
        if ('diff' -eq $RestoreType.ToLower()) {
            Invoke-DiffRestore @parms -ScriptOnly:$ScriptOnly
            }
        else {
            throw "You must specify whether you want a FULL or DIFF restore."
            }
        }
    }


Clear-Host

$parms = @{
    ConfigServer = 'spf-sv-delldb';
    ConfigDB = 'admin';
    RestoreType = 'full'
    GroupID = 1
    }

Start-Restore @parms -ScriptOnly #-Verbose

# Invoke-PSExecuteCommands @parms -CommandType 'full' -ScriptOnly

