Import-Module "\\gruyere\is\DBA\DBAs\DBA Powershell Scripts\Modules\TidalRefresh\TidalRefresh.psm1" -Force

Clear-Host

$parms = @{
    ConfigServer = 'spf-sv-delldb';
    ConfigDB = 'admin';
    RestoreType = 'diff'
    GroupID = 2
    }

 Start-PSRestore @parms -ScriptOnly

