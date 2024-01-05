<#
Return a string containing a SQL script given the SQL Script's associated label.
#>
function Get-PSSQLStatement {
    [cmdletbinding()]

    param (
        [Parameter(Mandatory = $true)]
        [string] $CommandType
        )

#-----------------------------------------------------------------------------------------------------
#  PLACE SQL SECTIONS BELOW THIS BANNER
#-----------------------------------------------------------------------------------------------------

    # Get the commands to add the users back after the restore.
    if ('Create Users' -eq $CommandType.ToLower()) {
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
    if ('Create Users Roles' -eq $CommandType.ToLower()) {
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
                @EncryptionKey = N'$EncryptionKey'
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
                @EncryptionKey = N'm#3rY@SP'
"@
        }

    if ('Backup Diff' -eq $CommandType.ToLower()) {
        $sql = @"
            exec dbo.xp_backup_database
                @database = '$Database',
                @filename = '$FolderPath',
                @with = 'DIFFERENTIAL',
                @init = 1,
                @encryptionkey = N'm#3rY@SP'
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
