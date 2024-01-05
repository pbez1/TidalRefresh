<#
Creates and saves SQL scripts that will restore those permissions to the restored database.  Saves to the tidal_users table.
NOT CERTIFIED FOR NEW TidalRefresh VERSION YET!
#>
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
        [string] $SystemName
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
    $sql = "select restore_to + '.' + dbname database_name from $ConfigDB.dbo.tidal_main where system_nm = '$SystemName' and group_id = $GroupID"
    $Databases = Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    foreach ($db in $Databases) {
        $src_server = $($db.database_name).split('.')[0]
        $dbname = $($db.database_name).split('.')[1]

        # Execute the SQL that retrieves the commands to store in tidal_users.
        Write-Verbose "Saving commands for database: $dbname"
        $sql = Get-PSSQLStatement -CommandType $CommandType
        $result_set = Invoke-Sqlcmd @sql_parms -ServerInstance $src_server -Database $dbname -Query $sql
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
                    Invoke-Sqlcmd @sql_parms `
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
            Invoke-Sqlcmd @sql_parms `
                -ServerInstance $ConfigServer `
                -Database $ConfigDB `
                -QueryTimeout 0 `
                -Query $insert_stmt
            }
        }
    }
