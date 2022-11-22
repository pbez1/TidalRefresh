# Import-Module "\\gruyere\is\DBA\DBAs\DBA Powershell Scripts\Modules\TidalRefresh\TidalRefresh.psm1" -Force
Import-Module "C:\Users\dba13\Documents\PS\PowerShell\TidalRefresh\TidalRefresh1.psm1" -Force

Clear-Host

$parms = @{
    ConfigServer = 'spf-sv-delldb';
    ConfigDB = 'admin';
    # SystemName = 'PD-DW'
    SystemName = 'QA-DW'
    RestoreType = 'full'
    GroupID = 2
    }

Clear-Host
Restore-PSBackups @parms -ScriptOnly

# Backup-PSAllDiffs @parms -ScriptOnly

# Start-PSRestoreAll @parms -Verbose -ScriptOnly

# Invoke-PSRunTSqlAll @parms -CommandType 'Save ERS Permissions' -ScriptOnly

