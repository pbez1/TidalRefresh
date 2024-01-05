<#
Orchestrates the post processing phase for either diff or full restore types.
NOT CERTIFIED FOR PRODUCTION YET!
#>
function Start-PSPostProcess {
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
        [switch] $ScriptOnly
        )

#-----------------------------------------------------------------------------------------------------
#  POST-PROCESS - DIFF SECTION
#-----------------------------------------------------------------------------------------------------

    if ('diff' -eq $RestoreType.ToLower()) {
#---->  Put any DIFF restore post process tasks between the two arrows.

        Write-Verbose "Post-Processing started."

        Invoke-PSPersistCommands @parms -CommandType 'Drop Users' -ScriptOnly:$ScriptOnly
        # Invoke-PSExecuteCommands @parms -CommandType 'Drop Users' -ScriptOnly:$ScriptOnly
        # Write-Verbose "Executing: exec dbo.AASP_PROV_NOT_FOUND_REFRESH"
        # # Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query 'exec dbo.AASP_PROV_NOT_FOUND_REFRESH'
        # Write-Verbose "Executing: update [dbo].[Token] SET [TokenValue] = 'BOGUS'"
        # # Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query "update [dbo].[Token] SET [TokenValue] = 'BOGUS'"
        # Write-Verbose "Executing: execute dbo.sp_ManageUsers 'HPXR', 0"
        # # Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query "execute dbo.sp_ManageUsers 'HPXR', 0"
        # Write-Verbose "Executing: update dbo.SYSTEM_PARAMETER set PARAMETER_VALUE = 'Y' where PARAMETER_NAME = 'START_LOAD'"
        # # Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query "update dbo.SYSTEM_PARAMETER set PARAMETER_VALUE = 'Y' where PARAMETER_NAME = 'START_LOAD'"
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
 