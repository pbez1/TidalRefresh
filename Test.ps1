# Import-Module "\\gruyere\is\DBA\DBAs\DBA Powershell Scripts\Modules\TidalRefresh\TidalRefresh.psm1" -Force
Import-Module "C:\Users\dba13\Documents\PS\PowerShell\TidalRefresh\TidalRefresh.psm1" -Force

Clear-Host

$parms = @{
    ConfigServer = 'spf-sv-delldb';
    ConfigDB = 'admin';
    RestoreType = 'full'
    GroupID = 1
    }

Clear-Host
Restore-PSBackups @parms -ScriptOnly

# Start-PSRestoreAll @parms -Verbose -ScriptOnly
