<#
Orchestrates the pre-processing phase for either diff or full restore types.
NOT CERTIFIED FOR PRODUCTION YET!
#>
function Start-PSPreProcess {
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
        [Parameter(Mandatory = $false)]
        [string] $Group = "1"
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

    # Delete all the rows from the tidal_user table in preparation for this batch.
    Write-Verbose 'Deleting all rows in the "tidal_user" table.'
    $sql = "delete $ConfigDB.dbo.tidal_user"
    Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql | Out-Null
        
#-----------------------------------------------------------------------------------------------------
#  PRE-PROCESS - FULL SECTION
#-----------------------------------------------------------------------------------------------------
    if ('full' -eq $RestoreType.ToLower()) {
#---->  Put any FULL restore post process tasks between the two arrows.

        # Get the commands to add the users back after the restore.
        Invoke-PSPersistCommands @parms -CommandType 'Create Users' -ScriptOnly:$ScriptOnly
        Invoke-PSPersistCommands @parms -CommandType 'Create Users Roles' -ScriptOnly:$ScriptOnly

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
