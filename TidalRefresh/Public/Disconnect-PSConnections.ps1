<#
Disconnects users from the target databases.
#>
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
        [string] $SystemName
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
    $sql = "select restore_to + '.' + dbname database_name from $ConfigDB.dbo.tidal_main where system_nm = '$SystemName' and group_id = $GroupID"
    $Databases = Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql

    foreach ($db in $Databases) {
        $src_server = $($db.database_name).split('.')[0]
        $dbname = $($db.database_name).split('.')[1]
        
        Write-Verbose "Disconnecting Connections to: $dbname"
        # $sql = @"
        #     ALTER DATABASE $dbname
        #     SET OFFLINE WITH ROLLBACK IMMEDIATE

        #     ALTER DATABASE $dbname
        #     SET ONLINE

        $sql = @"
            begin try
                -- Code to clean out any user connections before the snap
                use [master]

                -- Generates and executes an executable SQL script consisting of "Kill" statements that will kill any active spids.
                select @sql = substring(
                                (   select '; ' + 'Kill ' + convert(varchar(10), p.spid) 
                                    from sys.sysprocesses p 
                                    where p.dbid > 0 and db_name(p.dbid) = '$dbname' and p.spid > 50
                                    for xml path('')),
                                3, 
                                200000)
                if @sql is not null and @sql <> '' collate database_default
                    exec (@sql)
                end try
            begin catch
                set @msg = 'Error: Attempt to kill existing connections failed for database "$dbname"!  Pre snap processing did not complete: ' + Error_Message()
                raiserror(@msg, 11, 1)
                end catch
"@

        if ($ScriptOnly) {
            Write-Host $sql
            }
        else {
            # Invoke-Sqlcmd @sql_parms -ServerInstance $src_server -Database 'master' -Query $sql | Out-Null
            }
        }
    }
