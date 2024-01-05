#Requires -Version 5.1

#----------------------------------------------------------------------------------------
#                                 Module: PhaUtil.psm1
#----------------------------------------------------------------------------------------

#region Initialize_Module
# Specify the name of the module.
$ModuleName = 'TidalRefresh'

# PowerShell defaults to TSL 1.0.  Why?  Who knows.  TLS 1.0 pretty much went away around 
# 2018.  In any case, the call to any REST interface may fail (depending on the host
# server) without the following line of code.  As you might surmise, it sets TLS at # 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ScriptRoot must contain the path where this module can be found.  
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) {throw "`$ScriptRoot is empty or null.  Unable to determine the location of this module in the file system."}

# Establish this module file's location and read the configuration parameters (if any) from the associated local JSON file.
$ModuleJSON = "$ScriptRoot\$ModuleName.json"

if (Test-Path -Path $ModuleJSON) {$conf_parms = get-content -Path $ModuleJSON | ConvertFrom-Json}
else {throw "Can't find '$ModuleName.json' file.  $_"}

# Set manual global variables here.
$global:SqlScripts = Join-Path -Path $ScriptRoot -ChildPath $conf_parms.SqlScriptFolder

# Load Base Modules
Import-Module SQLSERVER -MinimumVersion $MinVerSQLSERVER -MaximumVersion $MaxVerSQLSERVER -ErrorAction Stop -Global

# Load Support Modules

# Create the variables from the contents of the JSON file.  JSON elements preceeded by a period "." will
# be instantiated as globals.  All other variables will be local to this module.
# Get the JSON property names.  These will be the global variable names.
$var_names = ($conf_parms | Get-Member -MemberType NoteProperty).Name
foreach ($var_name in $var_names) {
    # Default to local variable.
    $glbl = $false

    # Eliminate JSON "comment" entries.
    if ('_' -ne $var_name.Substring(0,1)) {
        # Get the value of the conf_parms.$var_name object member.
        $var_value = ($conf_parms.PSObject.Properties | 
            Where-Object {$_.name -eq $var_name} | 
            Select-Object value).value

        # Strip the leading "." if the variable has been marked as global.
        if ('.' -eq $var_name[0]) {
            $var_name = $var_name.trim().Substring(1, $var_name.trim().Length-1)
            $glbl = $true
            }

        # Remove the variable if it already exists.
        if (Get-Variable -Name $var_name -ErrorAction SilentlyContinue) {
            Remove-Variable -Name $var_name -Scope Global
            }

        # Create a new variable of local or Global scope based on whether there is a prepended period ".".
        # Variables starting with a period are global.
        if ($glbl) {New-Variable -Name $var_name -Value $var_value -Scope Global}
        else {New-Variable -Name $var_name -Value $var_value}
        }
    }

# Set any additional parameters for the Invoke-SqlCmd command.
# The JSON file must contain an array called "SqlCmdParms" if this hashtable is to be populated.
# This hashtable will be used to include any additional parameters to all "Invoke-SqlCmd" calls.
$global:sql_parms = @{}
if ("SqlCmdParms" -in $var_names -or ".SqlCmdParms" -in $var_names) {
    $var_value = ($conf_parms.PSObject.Properties | 
        Where-Object {$_.name -eq 'SqlCmdParms' -or $_.name -eq '.SqlCmdParms'} | 
        Select-Object value).value

    foreach ($parm in $var_value) {
        # Add the parameter to the Invoke-SqlCmd splat array.
        switch ($parm.Split('=')[1]) {
            "True"  {$sql_parms.Add(($parm.split("="))[0], $true)}
            "False" {$sql_parms.Add(($parm.split("="))[0], $false)}
            Default {$sql_parms.Add(($parm.split("="))[0], ($parm.split("="))[1])}
            }
        }
    }

# Set manual global variables here.

#endregion Initialize_Module

#----------------------------------------------------------------------------------------
#-- Load the module functions.
#----------------------------------------------------------------------------------------
#Get public and private function definition files.
$Public  = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files into this module.
Foreach($import in @($Public + $Private)) {
    try {
        . $import.fullname
        }
    catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
        }
    }

# Export Public functions
Export-ModuleMember -Function $Public.Basename
