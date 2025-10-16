# TidalRefresh

## Table of Contents
[Description](#description)<br>
[Functions](#functions)<br>
- [Backup-PSAllDiffs](#backup-psalldiffs)<br>

[TidalRefresh JSON File](#tidalrefresh-json-file)

## Description:
This module contains a variety of functions ranging from functions that produce output primarly for use by other functions to functions that produce results immediately useful to a DBA.

[Top](#tidalrefresh)
___
## Functions:
___
### Backup-PSAllDiffs
#### __Description__
Does DIFF backups of the specifed databases.

#### __Parameter__
- ConfigServer <br>
    This is the server that contains the TidalRefresh data tables.

- ConfigDB <br>
    This is the database that contains the TidalRefresh data tables.

- SystemName <br>
    This is the name of the target system, e.g. PD-DW, QA-DW

- RestoreType <br>
    This is the type of restore script to write: Full or Diff

- GroupID <br>
    This is the group ID of databases to process.  This group ID is the analog of the databases is each container in the SSIS job.

- ScriptOnly <br>
    If this parameter is provided, the function outputs the script it generates rather than running it.

[Top](#tidalrefresh)
___
## TidalRefresh JSON File
The following configurtion items can be found in the TidalRefresh.json file.<br>
Note: Elements preceded by a period "." are instantiated as global variables but without the prepended period in the variable name.  Otherwise, they are instantiated as local variables within the module.<br>
Example: .SqlCmdParms is instantiated as $global:SqlCmdParms.

|Variable                 | Description                                                                                                              |
|-------------------------|--------------------------------------------------------------------------------------------------------------------------|
| MinVerSQLSERVER         | This is the minimum version of the SQLSERVER module that is appropriate for this module.                                 |
| MaxVerSQLSERVER         | This is the maximum version of the SQLSERVER module that is appropriate for this module.                                 |
| ConfigurationServer     | This is the name of the SQL Server that contains the Tidal refresh data tables.                                          |
| ConfigurationDatabase   | This is the name of the SQL Server database that contains the Tidal refresh data.                                        |
| TableSchema             | This is the schema name of the TidalRefresh data tables.                                                                 |
| .SqlCmdParms            | This is an array of any additional parameters to pass to the Invoke-Sqlcmd cmdlet                                        |
|                         |                                                                                                                          |


[Top](#tidalrefresh)
___
