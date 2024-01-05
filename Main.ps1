Import-Module "C:\Users\dba13\Documents\PS\PowerShell\TidalRefresh\TidalRefresh\TidalRefresh.psm1" -Force

Clear-Host

$parms = @{
    # SystemName = 'PD-DW'
    SystemName = 'QA-DW'
    RestoreType = ''
    GroupID = 3
    }

Clear-Host
Restore-PSBackups @parms -ScriptOnly

# Backup-PSAllDiffs @parms -ScriptOnly

# Start-PSRestoreAll @parms -Verbose -ScriptOnly

# Invoke-PSRunTSqlAll @parms -CommandType 'Save ERS Permissions' -ScriptOnly
