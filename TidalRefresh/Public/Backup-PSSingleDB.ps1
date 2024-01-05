<#
Generates the SQL statement to backup a single database and optionally executes it.
#>
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
        [string] $SystemName
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

    Write-Verbose "Starting differential backup of: $Database"

    # Create the executable SQL statement to restore the database.  The SQL statement will be different depending
    # on the type of restore being done; whether FULL or DIFF.
    $sql = Get-PSSQLStatement -CommandType 'Backup Diff'

    # If the user only wants the SQL script, return it.  Otherwise, Execute the restore script.
    if ($ScriptOnly) {
        $sql
        }
    # else {
    #     # Invoke-Sqlcmd @sql_parms -ServerInstance = $TargetServer -Database 'master' -Query = $sql
    #     }
    }
