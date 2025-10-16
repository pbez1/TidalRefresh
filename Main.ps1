Import-Module "C:\Users\dba13\Documents\PS\PowerShell\TidalRefresh\TidalRefresh\TidalRefresh.psm1" -Force

Clear-Host

$parms = @{
    # SystemName = 'PD-DW'
    SystemName = 'PD-DW'
    RestoreType = 'diff'
    GroupID = 2
    }

Clear-Host
Restore-PSBackups @parms -ScriptOnly

# Backup-PSAllDiffs @parms -ScriptOnly

# Start-PSRestoreAll @parms -ScriptOnly -Verbose

# Invoke-PSRunTSqlAll @parms -CommandType 'Save ERS Permissions' -ScriptOnly
