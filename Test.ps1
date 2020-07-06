Import-Module .\TidalRefresh.psm1

Clear-Host

$parms = @{
    ConfigServer = 'spf-sv-delldb';
    ConfigDB = 'admin';
    RestoreType = 'diff'
    GroupID = 3
    }

Invoke-Restore @parms -ScriptOnly
# Invoke-DiffRestore @parms -ScriptOnly