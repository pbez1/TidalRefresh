<#
Runs the entire restore process from start to finish.
#>
function Start-PSRestoreAll {
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
        [string] $GroupID = "1"
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
                    Start-PSPreProcess @parms -ScriptOnly:$ScriptOnly 
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
