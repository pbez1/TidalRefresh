Import-Module .\TidalRefresh.psm1

Clear-Host

$parms = @{
    ConfigServer = 'spf-sv-delldb';
    ConfigDB = 'admin';
    RestoreType = 'diff'
    GroupID = 1
    }

Restore-PSBackups @parms -ScriptOnly

# Invoke-FullRestore @parms -ScriptOnly
# Invoke-DiffRestore @parms -ScriptOnly