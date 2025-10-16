<#
Runs the entire restore process from start to finish.
#>
function Start-PSRestoreAll {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $false)]
        [Parameter(Mandatory = $true)]
        [string] $SystemName
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType
        ,
        [Parameter(Mandatory = $false)]
        [string] $GroupID = "1"
        ,
        [string] $ConfigServer = $ConfigurationServer
        ,
        [Parameter(Mandatory = $false)]
        [string] $ConfigDB = $ConfigurationDatabase
        ,
        [Parameter(Mandatory = $false)]
        [switch] $ScriptOnly
        )

    switch ($SystemName) {
        'QA-DW' {
            switch ($RestoreType) {
                'full' {
                    Start-PSPreProcess @parms -ScriptOnly:$ScriptOnly 
                    Restore-PSBackups @parms -ScriptOnly:$ScriptOnly
                    Start-PSPostProcess @parms -ScriptOnly:$ScriptOnly
                    }
                'diff' {
                    Start-PSPreProcess @parms -ScriptOnly:$ScriptOnly 
                    Backup-PSAllDiffs @parms -ScriptOnly:$ScriptOnly
                    # Write-PSTriggerFile @parms -TriggerName 'Tidal Go Trigger'
                    Restore-PSBackups @parms -ScriptOnly:$ScriptOnly
                    Start-PSPostProcess @parms -ScriptOnly:$ScriptOnly
                    }
                default {
                    throw 'Invalid restore type.  The -RestoreType parameter must be either "full" or "diff"'
                    }
                }
            }

        'PD-DW'{
            switch ($RestoreType) {
                'full' {
                    Start-PSPreProcess @parms -ScriptOnly:$ScriptOnly 
                    Restore-PSBackups @parms -ScriptOnly:$ScriptOnly
                    Start-PSPostProcess @parms -ScriptOnly:$ScriptOnly
                    }
                'diff' {
                    Start-PSPreProcess @parms -ConfigServer $ConfigServer -ConfigDb $ConfigDB -ScriptOnly:$ScriptOnly 
                    # Backup-PSAllDiffs @parms -ScriptOnly:$ScriptOnly
                    # Write-PSTriggerFile @parms -TriggerName 'Tidal Go Trigger'
                    Restore-PSBackups @parms -ScriptOnly:$ScriptOnly
                    Start-PSPostProcess @parms -ScriptOnly:$ScriptOnly
                    }
                default {
                    throw 'Invalid restore type.  The -RestoreType parameter must be either "full" or "diff"'
                    }
                }
            }
        }
    }
