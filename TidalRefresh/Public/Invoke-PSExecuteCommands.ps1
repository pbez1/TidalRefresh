<#
Executes the SQL scripts that were saved to the tidal_users table by the Invoke-PSPersistCommands function.
NOT CERTIFIED FOR NEW TidalRefresh VERSION YET!
#>
function Invoke-PSExecuteCommands {
    [cmdletbinding()]

    param(
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
        [string] $ConfigServer = $ConfigurationServer 
        ,
        [Parameter(Mandatory = $false)]
        [string] $ConfigDB = $ConfigurationDatabase
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )
 
    $dt = Get-Date
    if (!$Revision) {$revision = "{0:yyyy-MM-dd HH:mm:ss}" -f $dt}

    # Get a list of the databases we intend to process from the tidal_main table.  
    # Include the server that contains the database that will be overwritten so we can extract the users list.
    Write-Verbose 'Getting the list of databases to process from the "tidal_main" table.'
    $sql = "select restore_to + '.' + dbname database_name from $ConfigDB.$TableSchema.v_tidal_all where system_nm = '$SystemName' and group_id = $GroupID and restore_type = '$RestoreType'"
    $Databases = Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    $cmd_stmt = ""

    foreach ($db in $Databases) {
        $src_server = $($db.database_name).split('.')[0]
        $dbname = $($db.database_name).split('.')[1]

        # Execute the SQL that retrieves the commands to store in tidal_users.
        $sql = Get-PSSQLStatement -CommandType $CommandType
        $result_set = Invoke-Sqlcmd @sql_parms -ServerInstance $src_server -Database $dbname -Query $sql
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
                    # Invoke-Sqlcmd @sql_parms `
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
            # Invoke-Sqlcmd @sql_parms `
            #     -ServerInstance $ConfigServer `
            #     -Database $ConfigDB `
            #     -QueryTimeout 0 `
            #     -Query $cmd_stmt
            }
        }
    }
