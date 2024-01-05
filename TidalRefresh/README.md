# PhaUtil

## Table of Contents
[Description](#description)<br>
[Functions](#functions)<br>
- [ConvertTo-ArrayFromDelimitedString](#convertto-arrayfromdelimitedstring)<br>
- [ConvertTo-DelimtedStringFromArray](#convertto-delimtedstringfromarray)<br>
- [Get-ArrayFromDelimitedString](#get-arrayfromdelimitedstring)<br>
- [Get-ArsPermissions](#get-arspermissions)<br>
- [Get-DelimtedStringFromArray](#get-delimtedstringfromarray)<br>
- [Get-PsArsRegistry](#get-psarsregistry)<br>
- [Get-PsCdcTables](#get-pscdctables)<br>
- [Get-PsDatabaseList](#get-psdatabaselist)<br>
- [Get-PsInstanceListFrom](#get-psinstancelistfrom)<br>
- [Get-PsInstanceName](#get-psinstancename)<br>
- [Get-PsOperator](#get-psoperator)<br>
- [Get-PsModuleVersion](#get-psmoduleversion)<br>
- [Get-PsOsVersion](#get-psosversion)<br>
- [Get-PsReverseString](#get-psreversestring)<br>
- [Get-PsSqlVersion](#get-pssqlversion)<br>
- [Get-RdpServerSessions](#get-rdpserversessions)<br>
- [Get-SecureStringClearText](#get-securestringcleartext)<br>
- [Install-AdminDatabase](#install-admindatabase)<br>
- [New-PsAdminDatabase](#new-psadmindatabase)<br>
- [New-PsAdminMaintObjects)](#new-psadminmaintobjects)<br>
- [New-PsBlitzObjects)](#new-psblitzobjects)<br>
- [New-PsWhoIsActive)](#new-pswhoisactive)<br>
- [Register-PhaRepository](#register-pharepository)<br>
- [Revoke-DatabaseConnections](#revoke-databaseconnections)<br>
- [Test-ExportPath](#test-exportpath)<br>
- [Test-PsDbReadiness](#test-psdbreadiness)<br>
- [Write-CenterBanner](#write-centerbanner)<br>

[PhaUtil JSON File](#phautil-json-file)<br>
- [Create The ARS Registry Log Table](#create-the-ars-registry-log-table)

## Description:
This module contains a variety of functions ranging from functions that produce output primarly for use by other functions to functions that produce results immediately useful to a DBA.

[Top](#phautil)
___
## Functions:
___
### *ConvertTo-ArrayFromDelimitedString*
#### __Description__
This function accepts an character delimited string and returns an array of string consisting of the delimited string elements.  As a part of this process, it will optionally remove any single or double quotes from the string prior to creating the array.

This function will also accept an array of string.  However, the function will simply return that very same array back to the caller.  This feature is useful when it's not clear whether the supplied variable is delimited string or already an array.  Simply pass the variable, whether delimited string or string array, and the result will be a string array.

(Formerly, this function was named Get-ArrayFromDelimitedString)

#### __Parameter__
- DelimitedStr <br>
    This is the delimited string (or array) to convert to an array.

- Delimiter <br>
    This is the character that will act as the delimiter for the $DelimitedStr parameter.

- AllowQuotes <br>
    This will preserve any single or double quotes present in the DelimitedStr parameter.  The default is to strip single an double quotes from the string prior to creating the array.

[Top](#phautil)
___
### *ConvertTo-DelimtedStringFromArray*
#### __Description__
This function accepts a character string array and delimiter character and returns a delimited string consisting of the array string elements.

This function will also accept a single delimited (or non-delimited) string.  However, the function will simply return that very same delimited string back to the caller.  This feature is useful when it's not clear whether the supplied variable is delimited string or already an array.  Simply pass the variable, whether delimited string or string array, and the result will be a delimited string.

(Formerly, this function was named Get-DelimtedStringFromArray)

#### __Parameters__

- StringArray<br>
    This is the the string array (or delimited string) to convert to a delimited string.

- Delimiter<br>
    This is the character that will act as the delimiter for the returned delimited string.

- SqlInString<br>
    When this parameter is provided, the returned string will be in the form of a SQL "in" string, e.g. 'one', 'two', 'three' This is the character that will act as the delimiter for the returned delimited string.
___
### *Get-ArrayFromDelimitedString*
#### __Description__
DEPRECATED: Use ConvertTo-ArrayFromnDelimitedString instead.

This function accepts an character delimited string and returns an array of string consisting of the delimited string elements.  As a part of this process, it will optionally remove any single or double quotes from the string prior to creating the array.

This function will also accept an array of string.  However, the function will simply return that very same array back to the caller.  This feature is useful when it's not clear whether the supplied variable is delimited string or already an array.  Simply pass the variable, whether delimited string or string array, and the result will be a string array.

#### __Parameter__
- DelimitedStr <br>
    This is the delimited string (or array) to convert to an array.

- Delimiter <br>
    This is the character that will act as the delimiter for the $DelimitedStr parameter.

- AllowQuotes <br>
    This will preserve any single or double quotes present in the DelimitedStr parameter.  The default is to strip single an double quotes from the string prior to creating the array.

[Top](#phautil)
___
### *Get-ArsPermissions*
#### __Description__
This function retrieves the most recent permissions creation script created by the ARS/ERS system for the specifed server and database.

The function offers several different modes of operation.<br>
Modes:
1) Most recent permissions script
    Given either the Server and Database name -or- the Permissions ID (PermId) this function will return the most recent permissions script generated by the ARS/ERS system on that server.
2) Permissions script list
    Given the Server and Database name, this function will return a list consisting of the Permission ID and the date it was created.  This is simliar to the SQL "Top 10" clause used with T-SQL when retrieving a similar list.  The list defaults to the most recent 10 scripts but may be adjusted to any number by
    specifying the number desired with the -ListCount parameter.
3) Permissions scripts count
    Given the Server and Database name, this function will return the number of permission scripts available for each database.  Since the permission script table is rarely truncated, these counts can become quite large.
4) Edit the permissions script
    Given either the Server and Database name -or- the Permissions ID (PermId) this function will open the selected permissions script in Windows Notepad for editing, cutting and pasting or any other operation available in a text editor.
5) Save permissions script to a file.
    Given either the Server and Database name -or- the Permissions ID (PermId) along with the -FilePath parameter, this function will save the permissions script to a file on the file system.

#### __Parameters__

- Server<br>
    This is the name of the server hosting the ARS/ERS system containing the desired permission script.

- DbName<br>
    This is the name of the database whose permission script will be retrieved.

- SaveDate<br>
    This parameter allows the caller to supply the date a permission script was created.  This date must be in the form: "yyy-mm-dd".  No time component is accepted.  If this parameter is supplied, the function will return the most recent permission script created on the specified day.

    This is an alternate way of specifying the desired permission script from the more precise two step process wherein the caller executes this function with the -GetList parameter, chooses the permission script ID from the list then executes this function again passing that ID to the -PermId parameter.

- PermId<br>
    This is the value of the "Id" column in the RefreshPermissionScripts table that corresponds to the desired permission script.  A list of permission ID's can be retrieved using the -GetList parameter of this function.

    NOTE: The -DbName parameter and this parameter are mutually exclusive.

- GetList<br>
    If this parameter is used, the function will return a list consisting of the Permission ID and the date the permission script was created.  The list defaults to the most recent 10 scripts but may be adjusted to any number by specifying the number desired with the -ListCount parameter.

- GetCount<br>
    If this parameter is supplied, this function will return the number of permission scripts available for each database.  Since the permission script table is rarely truncated, these counts can become quite large.

- Edit<br>
    If this parameter is supplied, this function will open the selected permissions script in Windows Notepad for editing, cutting and pasting or any other operation available in a text editor.

- ListCount<br>
    This parameter is used only in conjunction with the -GetList parameeter.  When supplied with a numeric value, this function will return a list of -ListCount lines consisting of the Permission ID and the date the permission script was created.

- FilePath<br>
    When this parameter is supplied, the permission script is saved to the specified file on the file system.  As the parameter name implies, the full path name is required.

- MaxResultChars<br>
    PowerShell output is limited to a smaller number of charaters than is present in many of the permissions scripts.  The value of this parameter defaults to 20,000,000 in this function which is sufficient for most permission scripts.  It can be increased as necessary by the caller, however, if 20,000,000 characters is not sufficient.

- EnvRefDB<br>
    This is the name of the ARS/ERS database that hosts the RefreshPermissionScripts table.  This defaults to "admin" which has historicallly been the only database used for this system at PacificSource.  However, should that change, the proper database can be specified here.

- Silent<br>
    If this parameter is passed, only the permissions script will be returned.  Otherwise, additional information may be included (such as header information).

[Top](#phautil)
___
### *Get-DelimtedStringFromArray*
#### __Description__
DEPRECATED: Use ConvertTo-DelimitedStringFromArray instead.

This function accepts a character string array and delimiter character and returns a delimited string consisting of the array string elements.

This function will also accept a single delimited (or non-delimited) string.  However, the function will simply return that very same delimited string back to the caller.  This feature is useful when it's not clear whether the supplied variable is delimited string or already an array.  Simply pass the variable, whether delimited string or string array, and the result will be a delimited string.

#### __Parameters__

- StringArray<br>
    This is the the string array (or delimited string) to convert to a delimited string.

- Delimiter<br>
    This is the character that will act as the delimiter for the returned delimited string.

- SqlInString<br>
    When this parameter is provided, the returned string will be in the form of a SQL "in" string, e.g. 'one', 'two', 'three' This is the character that will act as the delimiter for the returned delimited string.
___
### *Get-PsArsRegistry*

#### __Description__
This function accepts a list of SQL Servers to inspect, then aggregates the ARS/ERS environment parameter information present in each one of those servers into a cohesive whole.

The function returns one of two possible result sets:<br>
1) Instance Status:<br>
   This option returns the status of ERS/ARS for each of the specified servers.<br>
   Statuses include:<br>
    a) ARS               - The instance has a valid ARS installation.<br>
    b) ERS               - The instance has been updated to ERS<br>
    c) Not Installed     - ARS is not installed<br>
    d) MalFormed Install - The installed version does not comply with current standards.

2) Information from the RefreshEnviornmentParameters table/view<br>
    a) This data represents the content of each of the RefreshEnvironmentRefresh tables/views from each of the specified servers.

This function also offers three modes for handling the returned data:<br>
1) By default, data from #1 above is returned as an Install-Status object to the calling probram.
    - This returned data may be manipulated by Powershell in all the usual ways (filtering, sorting, etc.).
2) The caller may specify the -FullData parameter. In this case, data from #2 above is returned as a Full-Data object to the calling program.
    - This returned data may be manipulated by Powershell in all the usual ways (filtering, sorting, etc.).
3) The caller may specify the -ExportToTable parameter.
    - This parameter will cause the data in the RefreshEnvironmentParameters table to be added to a specific destination table.  In this way, multiple server's RefreshEnvironmentRefresh data can be written to a single table for comparison or to maintain an easily searchable repository.  The location of the table may be specified by supplying the relevent information to the function in the -ArsLogInstance, -ArsLogDatabase, and -ArsLogTable parameters (any combination of these three parameters are allowed with the unspecified parameters reverting to their defaults).  If these parameters are not provided, the location defaults to the admin.dbo.ars_registry table on the current server.  (If you accept the server instance default and run this function from a non-SQL Server, an error will be thrown.)
    
    - The -Truncate parameter is compatible with the -ExportToTable parameter and if selected, will result in an existing table being truncated, thereby clearing any prior data.

    - When this parameter is passed, this function returns a Full-Data object rather than an Install-Status object.
   
#### __Parameters__
- InstanceList<br>
    This parameter contains the list of SQL Server instances to inspect.

- FullData<br>
    Directs the function to return a Full-Data object containing the aggregate RefreshEnvironmentRefresh data of all servers inspected.

    If this parameter or the -ExportToTable parameter is NOT passed, this function returns an Install-Status object.

- ExportToTable<br>
    Directs the fundtion to write the RefreshEnvironmentRefresh data to the "$ArsRepoDatabase" database in the "$ArsRepoInstance" SQL Server instance.

    When this parameter is passed this function will also return a Full-Data object to the caller in addition to writing that information to the "ars_registry" table.

- ArsHostDatabase<br>
    This is the nanme of the database that hosts the ARS/ERS on the server begin inspected.

- ArsLogInstance<br>
    This is the name of the SQL Server instance that hosts the table the output of this function will be saved to when the -ExportToTable parameter is passed.

- ArsLogDatabase<br>
    This is the name of the database that hosts the table the output of this function will be saved to when the -ExportToTable parameter is passed.

- ArsLogTable<br>
    This is the name of the database that hosts the table the output of this function will be saved to when the -ExportToTable parameter is passed.

- Force<br>
    When the -ExportToTable parameter is supplied, the function will copy the information from the RefreshEnvironmentParameters table to the table name described by the -ArsLogTable parameter.  If the Force parameter is provided, the function will overwrite any table with the same name if one exists.  Otherwise, it will return with an error.

[Top](#phautil)
___
### *Get-PsCdcTables*
#### __Description__
This function returns inforamtion about which servers, databases and tables are enabled for Change Data Capture (CDC) at PacificSource.

Several modes of operation are available:<br>
1) Servers, databases and tables<br>
    The name of the database for which CDC is enabled along with any CDC enabled tables.<br>
2) Databases Only<br>
    Returns only the servers and databases for which CDC is enabled.
3) Passthrough<br>
    No output to the display is generated.  Rather a PsCustomObject of the following format is returned:
    [string] server<br>
    [string] database<br>
    [string[]] tables<<br>>

There are several filtering options:<br>
1) If a value is passed in the -Database parameter, data for that specific database only will be returned.
2) The -WhereTableLike parameter accepts a string for comparison to the actual table name.  Wildcards are supported.
3) The -NoSchemas parameter returns only the table name with no schema indicated.
4) The -ShowProgress parameter lists each server as it is processed.

#### __Parameter__
- ServerInstance<br>
    This is the name of the Server to inspect.  Multiple servers may be passed to this function as a comma separated list of names or as a preconstructed array of server names.

    This parameter may will accept values from the pipeline.

- Database<br>
    If a database name is passed in this parameter, information for that database alone will be returned.

    For example:<br>
    Get-PsCdcTables -ServerInstance 'FACETSDB' -Database 'FACETS'

    Will return information for the FACETS table only.  Any other CDC Enabled database found on the server will be ignored.

- WhereTableLike
    This allows the caller to filter the output of this functions to table names that match the filter criteria.  Wildcards are supported.

    For example:<br>
    Get-PsCdcTables -ServerInstance 'FACETSDB' -Database 'FACETS' -WhereTableLike 'CMC_*'<br>
    Will return only tables that start with "CMC_"

- DatabaseOnly<br>
    If this parameter is supplied, output will be limited to returning only CDC enabled databases.  Their CDC enabled tables will not be returned.

- ShowProgress<br>
    If this parameter is included, the output will include a running display of each server name as it is processed.

- NoSchemas<br>
    If this parameter is included, the output of table names will omit the corresponding schema name.  Only the table names will be displayed.  Note: It is possible for two tables to share the same name but reside in different schemas.  If this parameter is supplied, it will be impossible to disambiguate two tables with the same name.

- PassThrough<br>
    If this parameter is included, nothing will be output to the display.  Rather, a PsCustomObject of the following format will be returned instead:<br>
        [string] server<br>
        [string] database<br>
        [string[]] tables<br>

[Top](#phautil)
___
### *Get-PsDatabaseList*
#### __Description__
This function returns the list of database names hosted by the specified SQL Server instance(s).

If more than one SQL Server instance is supplied, the database names for each of the SQL Server instances will be returned.

This function defaults to returning both the server names and the database names unless the user specifies the -DatabaseNamesOnly parameter.  NOTE: The -DatabaseNamesOnly parameter will *only* be honored if the -ServerList parameter contains one SQL instance name.  If the -ServerList parameter contains more than one SQL Server instance, the server name will be included automatically, regardless of the -DatabaseNamesOnly parameter, to allow the caller to disambiguate the database names in the list.
#### __Parameters__
- ServerList<br>
    This is the list of server names to retrieve the database list from.

- DatabaseNamesOnly<br>
    If this parameter is included AND the caller passed only one SQL Server instance name, the function will return only a list of database names.  Otherwise, it will return both the server name and the database name.

- IncludeSystemDbs<br>
    If this parameter is included the function will include the system databases (master, msdb, model, temp, distribution) in the results.  Otherwise, these databases are omitted.

[Top](#phautil)
___
### *Get-PsInstanceListFrom*
#### __Description__
Returns a list of SQL Servers as maintained by a variety of different PacificSource source catalogs.  Currently supported: DSI, CMS, DBA_DB.

A list of servers is often at the heart of many processing tasks.  For SQL Servers at PacificSource, there are several sources for such lists.  As of this writing, lists exist in at least three places: CMS, DBA_db, and DSI.  Each of these sources maintains a list of PacificSource's SQL servers in a database.

This function retrieves a list of SQL Servers from any of the supported sources which, as of this writing, is: DSI, CMS or DBA_db.  (MDS is stubbed into this code for future support but is not currently implemented.)

This function also provides some simple ability to filter the results by the environment in which the SQL Server resides.  For example, the caller may return only the SQL Servers designated as Production, or perhaps as QA or DEV.

#### __Parameters__
- ServerListSource
    This parameter allows the user to select a source for the list of SQL Server names this function will check for RDP connections.  Valid sources as of this writing are DSI", "CMS", "DBA_db" and "MDS" though "MDS" is stubbed in for future use and has *not* yet been implemented.  (These "sources" are databases that each contain their own list of PacificSource SQL Servers.)  Example: ServerListSource DSI

    Note: DSI is generally the most up-to-date list.  DSI is updated nightly, CMS is updated on an ad hoc basis, DBA_db is updated monthly.

    Defaults to: DSI

    This parameter is mutually exclusive with -ServerList.

- Environment <br>
    This is an optional parameter that allows the user to filter the list obtained from the source defined by -ServerListSource.  Valid values differ based on the source.  As of this writing, however, they are as follows: <br>
    DSI    : "DEV", "PROD", "PRD", "QA", "DBA", "TRN", "POC" <br>
    CMS    : "DEV", "PROD", "PRD", "QA" <br>
    DBA_db : "DEV", "PROD", "PRD", "QA" <br>

    Defaults to: All

    This parameter is mutually exclusive with -ServerList.

- Server <br>
    THIS PARAMETER WILL RARELY BE NEEDED!  Each Server list source maintains a list of SQL Servers in a database on a particular server.  With a few exceptions, this host server will not often change.  This parameter is included only to allow the caller to change the name of that source server from its default.  This will be necessary only rarely but on the off chance the server name does change, this parameter can be supplied by the caller to change the name of the target server without the risk of modifying this function's code.

    This parameter *must* be used in conjunction with the -ServerListSource parameter and must point to the server associated with the chosen source.

    Defaults to the server associated with the -ServerListSource definition.  These values are configurable from the PhaUtil.json file.  For example: DSI defaults to "sdc-sqldbadb", DBA_db defautlts to "spf-dv-sql07", etc.

- DbName <br>
    THIS PARAMETER WILL RARELY BE NEEDED!  Each Server list source maintains a list of SQL Servers in a database on a particular server.  With a few exceptions, this database is often determined by Microsoft and is unlikely to change.  This parameter is included only to allow the caller to change the name of that source database from its default should the need arise without the risk of modifying this function's code.

    This parameter *must* be used in conjunction with the -ServerListSource parameter and must point to the database associated with the chosen source.

    Defaults to the database associated with the -ServerListSource definition.  These values are configurable from the PhaUtil.json file.  For example: DSI defaults to "sdc-sqldbadb", DBA_db defautlts to "spf-dv-sql07", etc.

- ServerNameOnly <br>
    If this parameter is included, the output will contain only server names.  Instance names (as in a named instance) will be removed.  So, SAGE\WEBDB, for example, will return only SAGE.

[Top](#phautil)
___
### *Get-PsInstanceName*
#### __Description__
This function formats a server name and a SQL Server instance name into the full SQL Server "Server\Instance" name.

The server name is passed in the $Server parameter and the instance name, if any, is passed in the $NamedInstanceName parameter.
If the $NamedInstanceName parameter is left blank, this function will simply return the server name without an instance
component.

#### __Parameter__
- Server<br>
    This is the name of the server name that hosts the SQL Server instance.

- NamedInstanceName<br>
    This is the instance name part of a named SQL Server.

- ExportPath<br>
    Not Used!  This is included in order to accept the Splat Parameters from other calling functions.

[Top](#phautil)
___
### *Get-PsModuleVersion*
#### __Description__
This function returns the version number of the latest installed PowerShell module(s) on the specified computer(s).

This function offers three modes of operation:<br>
1) No Parameters<br>
    - Returns the version numbers of all of the PowerShell modules in the "AllUsers" folder (c:\Program Files\WindowsPowerShell\modules) for all of the computers specified.
2) Specify the module name<br>
    - Returns the version number of that specific module on all of the computers specified.
3) Module an version number specified.<br>
    - Returns the version number if there is a module by that name and version on the computer.  Otherwise, it returns a value of "NA (<searched_version>)".

#### __Parameter__
- Module<br>
    This is the name of the module being searched for.

- Server<br>
This is the name of the server that hosts the module.

- Version<br>
This is the version number to search for.  If this parameter is supplied, this function will respond with whether or not that version is installed on the computer.  If it is not supplied, the function will return the maximum version available on the computer.

- ShowLatest<br>
If this parameter is included, the latest version of the module available at the specified repository will be included in the output.

.Parameter Repository
This is the name of the repository to register if it's not already registered.  It defaults to the value of "PSRepo_Name" in
the JSON file.

.Parameter RepositoryPath
This is the location (path) of the repository named in the -Repository parameter.  It defaults to the value of $PSRepo_Location
in the JSON file.
        
- RepoToSearch<br>
If this parameter is supplied, this function will search the specified repository for the latest available version of the specified module.

- PassThrough<br>
When this parameter is passed, all informational output is suppressed.  The function returns a PsCustomObject containing the results of the search.

[Top](#phautil)
___
### *Get-PsOperator*
#### __Description__
This function returns a table of SQL Agent operators along with an index number for each.  It then prompts the user to select
one of the operators by typing its index number on the command line.  It then returns the selected operator text.

This function is useful in allowing the user to interactively determine which operator to use in any given scenario.

#### __Parameter__
- ServerInstance<br>
    This is the name the SQL Server instance to get the operator list from.

- SelectOne<br>
    If this parameter is included the user will be prompted to select one of the operators from a list.  The function will then return that operator to the caller.

[Top](#phautil)
___
### *Get-PsOsVersion*
#### __Description__
Returns the Windows Operating System version from the specified computer.

Multiple output formats are supported:<br>
1) Default output includes server name and version<br>
    - sdc-dwqa : 2019<br>
2) When -IncludeEdition parameter is passed, the edittion is also included in the output.<br>
    - sdc-dwqa : 2019 Datacenter<br>
2) When -ExcludeServerFromOutput parameter is passed, the server is removed from the output.<br>
    - 2019 Datacenter<br>

#### __Parameter__
- Server<br>
    This is the name of the server to retrieve the version information from.

- IncludeEdition<br>
    When this parameter is passed, the server edition is include in the output.

- Silent<br>
    When this parameter is passed, all informational output is supporessed.

[Top](#phautil)
___
### *Get-PsReverseString*
#### __Description__
Reverses any string passed to it.

PowerShell 5.1 has no reverse string function so this function fills that gap.

Reverse a string can often simplify searching a string for a particular element.

#### __Parameter__
- StringToReverse<br>
    This holds the contents of the string to reverse.  The function return result is the reversed string.

[Top](#phautil)
___
### *Get-PsSqlVersion*
#### __Description__
Returns the version of SQL Server from the specified server.

The return value is simply the SQL Server version year.  For example, "2019".

- InstanceList<br>
    This is a list of names for each of the SQL Servers to return the version from.

[Top](#phautil)
___
### *Get-RdpServerSessions*
#### __Description__
Most servers allow up to 2 remote connections/sessions.  This function accepts a list of servers to check for these connections then reports any connections found to the standard output (usually the display).

#### __Parameter__
- ServerListSource<br>
    This parameter allows the user to select a source for the list of SQL Server names this function will check for RDP connections.  Valid sources as of this writing are "DSI", "CMS", and "DBA_db".  (These are databases that each contain their own list of PacificSource SQL Servers.)  Example: ServerListSource DSI

    Note: DSI generally has the most current list.

    This parameter is mutually exclusive with -ServerList.

- Environment<br>
    This is an optional parameter that allows the user to filter the list obtained from the source defined by -ServerListSource.  Valid values differ based on the source.  As of this writing, however, they are as follows:<br>
    DSI    : "DEV", "PROD", "PRD", "QA", "DBA", "TRN", "POC"<br>
    CMS    : "DEV", "PROD", "PRD", "QA"<br>
    DBA_db : "DEV", "PROD", "PRD", "QA"<br>

    This parameter is mutually exclusive with -ServerList.

- ServerList<br>
    This parameter allows the caller to specify the servers to be checked.  It is an array of server names.  Example: -ServerList 'sdc-dwdv', 'sdc-dwqa', 'sdc-dwetldv'.

    This parameter is mutually exclusive with -ServerListSource and -Environment.

- FullListing<br>
    If this parameter is included, the output will contain the names of all of the servers checked, otherwise only the servers where connections are found will be output to standard out (usually the display).

[Top](#phautil)
___
### *Get-SecureStringClearText*
#### __Description__
Sometimes it is useful to "decrypt" a PowerShell SecureString into its original clear text.  This function performs that decryption.

It's essential to note that this function will NOT decrypt the SecureString for a login account other than the one that encrypted the SecureString in the first place.  Moreover, it must not only be the original login account but it must performed on the same compueter that performed the encryption.   In other words, if the caller has not created a session with the account used to encrypt the SecureString on the computer from which the original encryption took place, this function will fail.

It can be assumed that since the account decrypting the SecureString is the same one that encrypted it originally, no new secrets are being revealed.

#### __Parameter__
- SecureValue<br>
    This is the PowerShell SecureString that contains the password to be decrypted.

[Top](#phautil)
___
### *Install-AdminDatabase*
#### __Description__
This function creates the "admin" database on the target server and populates it with all of the default objects listed
in the PhaUtil.JSON file.  If an "admin" database already exists on the server, this function can optionally replace it
by including the -Force parameter in the function call.

The "admin" database is the database used for SQL Server administration and as such contains data and objects that support
that goal.  The data and objects present on any given SQL Server instance may vary widely but all servers will support the
following default systems:
1) Management Objects (Ola Hallengren objects)
2) Who Is Active (by Adam Mechanic)
3) The Blitz First Responder Kit (by Brent Ozar)
4) The PacificSource Automated Refresh Service (ARS)

Though all SQL Server instances will support these four basic services, there may be occasions where one or more is not
desired.  In those cases, the list may be adjusted by modifying the "AdminOjbectsToDeploy" array in the PhaUtil.JSON
file.  The only four acceptable text strings in that array are:
- ManagementObjects
- WhoIsActive
- Blitz
- ARS
#### __Parameter__
- ServerInstance<br>
    This is the name the SQL Server instance to create the 'admin' database on.

- DbDataPath<br>
    This is the default path to the "admin" database's data file.  This defaults to the SQL Server instance's default data file path.

- DbLogPath<br>
    This is the default path to the "admin" database's log file.  This defaults to the SQL Server instance's default log file path.

- Force<br>
    Including this parameter will result in any existing 'admin' database being overwritten with a new one.

[Top](#phautil)
___

### *New-PsAdminDatabase*
#### __Description__
This function creates the "admin" database on the target server.  If an "admin" database already exists on the server, this
function can optionally replace it by including the -Force parameter in the function call.

The function simply executes the T-SQL script with the name "create_admin_database.sql" located in the SqlScripts folder against
the target server after replacing any embedded replacement tokens within the script.  Any desired modifications to the "admin"
database prior to creation may be made to that script.

#### __Parameter__
- ServerInstance<br>
    This is the name the SQL Server instance to create the 'admin' database on.

- DbDataPath<br>
    This is the default path to the "admin" database's data file.  This defaults to the SQL Server instance's default data file path.

- DbLogPath<br>
    This is the default path to the "admin" database's log file.  This defaults to the SQL Server instance's default log file path.

- Force<br>
    Including this parameter will result in any existing 'admin' database being overwritten with a new one.

[Top](#phautil)
___
### *New-PsAdminMaintObjects*
#### __Description__
Adds the "Management Objects" to the "admin" database.  The "Management Objects" consist mostly of the Ola Hallengren
scripts which manage index defragmentation, rebuilds and the like.  (See Ola Hallengren documentation for more detailed
information: https://ola.hallengren.com)

This function simply executes the T-SQL script with the name "maintentance_solution.sql" located in the SqlScripts folder, against
the target server after replacing any embedded replacement tokens within the script.  Any desired modifications to the "ola hallengren"
scripts prior to creation may be made by editing that script.

#### __Parameter__
- ServerInstance<br>
    This is the name the SQL Server instance to create the 'admin' database on.

- CreateJobs<br>
    This parameter is passed to the "maintenance_solution" script to satisfy an internal Ola Hallengren script parameter.  Presumably, it controls whether SQL Agent jobs are created or not.  Defaults to: "Y"

    See Ola Hallengren documentation for more details regarding this parameter.

- BackupDirectory<br>
    This parameter is passed to the "maintenance_solution" script to satisfy an internal Ola Hallengren script parameter.  Defaults to: null

    See Ola Hallengren documentation for more details regarding this parameter.

- CleanupTime<br>
    This parameter is passed to the "maintenance_solution" script to satisfy an internal Ola Hallengren script parameter.  Defaults to: null

    See Ola Hallengren documentation for more details regarding this parameter.

- OutputFileDirectory<br>
    This parameter is passed to the "maintenance_solution" script to satisfy an internal Ola Hallengren script parameter.  Defaults to: null

    See Ola Hallengren documentation for more details regarding this parameter.

- LogToTable<br>
    This parameter is passed to the "maintenance_solution" script to satisfy an internal Ola Hallengren script parameter.  Defaults to: "Y"

    See Ola Hallengren documentation for more details regarding this parameter.

[Top](#phautil)
___
### *New-PsBlitzObjects*
#### __Description__
This function creates the Brent Ozar First Responder's Kit objects in the 'admin' database on the target SQL Server instance.

The function simply executes a T-SQL installation script (downloaded from Brent Ozar's web site) and located in the SqlScripts
folder, against the 'admin' database on the target server.  Any desired modifications to the First Responder scripts prior to
creation may be made to that script.

Brent Ozar offers three different installation scripts to choose from:
1) Install All scripts
2) Install Basic scripts without Query Store
3) Install Basic scripts with Query Store.

This function supports all three installation scripts but defaults to the most basic: "Install Basic Scripts without Query Store".
To select one of the other installations, the -ScriptName parameter must be used and it must be passed only one of the following
three values (anything else will result in an error):
- All-Scripts
- No-Query-Store
- With-Query-Store

#### __Parameter__
- ServerInstance<br>
    This is the name the SQL Server instance to create the 'admin' database on.

- ScriptName<br>
    Determines which installation script will be used to install the First Responder Script.  Must be one of: 
    - All-Scripts
    - No-Query-Store
    - With-Query-Store

    Defaults to: "No-Query-Store"

[Top](#phautil)
___
### *New-PsWhoIsActive*
#### __Description__
This function creates the Adam Mechanic stored procedure called "sp_WhoIsActive" in the 'admin' database on the target SQL Server
instance.

The function simply executes a T-SQL installation script (downloaded from the GitHub web site) and located in the SqlScripts
folder, against the 'admin' database on the target server.  Any desired modifications to the "sp_WhoIsActive" stored procedure
prior to creation may be made to that script.

This function checks several things to assure the script executes successfully:
1) It retrieves the surrogate "sa" user from the target server and substitutes that user into the sp_WhoIsActive script's @owner_login_name parameter.  This is usually "Kylo Ren" but on some servers it could be different.
2) The default email notification operator for the sp_WhoIsActive stored procedure is "SQL Admins - Email Only".  If that operator isn't present on the target server, the sp_WhoIsActive script will fail and this function will abort.  To prevent this from happening, when the default operator is not present on the server, this function will display a list of the operators that *are* present on the target server and will prompt the user to choose one to receive email notification.  Only if the user fails to do this, will the function terminate abnormally.
#### __Parameter__
- ServerInstance<br>
    This is the name the SQL Server instance to create the 'admin' database on.

- OmitLoggingJob<br>
    If this parameter is passed, the SQL Agent job that logs the results of the sp_WhoIsActive stored procedure will NOT be created.

[Top](#phautil)
### *Register-PhaRepository*
#### __Description__
Registers the PacificSource PowerShell repository for the current user on the current computer.  The default repository name and location are defined in the PhaUtil.json file.  The values can be overridden, however, by passing appropriate values to the -$RepositoryName and -RepositoryPath parameters.

#### __Parameter__
- RepositoryName<br>
This is the name the repository will be known to PowerShell by.

- RepositoryPath<br>
This is the network share that hosts the repository.

[Top](#phautil)
___
### *Revoke-DatabaseConnections*
#### __Description__
The function accepts a SQL Server name and database name then kills any open connections to that database.  This must be done to preparation the database to be taken offline.

The currently acceptable method for killing connections is to change the database to Single User mode.  In doing so, all conncections are dropped.  The risk is that another connection may be established blocking you from connecting to the database for administrative functions.  

Because of the above, this function defaults to changing the database back to Multi-User mode immediately following successfully changing it to Single User mode.  The risk with that, of course, is that multiple other connections can then be re-established preventing you from peforming some administrative tasks.

To prevent the function from reentering Multi-User Mode, include the -LeaveAsSingleUser parameter.  That database will then be left in Single User mode.

#### __Parameter__
- DestServer<br>
    This the Server hosting the database whose connections will be terminated.

- $DbName<br>
    This the database who's connections will be terminated

- $LeaveAsSingleUser<br>
    If this parameter is supplied, the database is left as Single User.  Otherwise, it's left as Multi User.

[Top](#phautil)
___
### *Test-ExportPath*
#### __Description__
Tests whether a folder path exists and if not, creates it.

#### __Parameter__
- ExportPath<br>
    This can either be the full pathname to test/create, or a parent path.  If it's the parent path, then the -ChildPath parameter must contain a value and will be concatenated to the end of this value to create the full path.

- ChildPath<br>
    This is a child path if needed.  If this value is supplied, it will be concatenated to the end of the -ExportPath parameter to create the full path

- AbortOnError<br>
    Determines whether this function throws an error or writes a warning if an exception occurs.

[Top](#phautil)
___
### *Test-PsDbReadiness*
#### __Description__
This function verifies the readiness of a SQL Server instance and any databases specified to be taken offline.  With respect to a database, in order for it to be taken "offline" it must first be "online".  Though that may sound silly, there are many states a database can be in other than offline or online.

This function verifies that the SQL Server instance is available and that databases contained in the -Databases string array parameter are all in the "online" state.  If everything is ready, the function returns null, otherwise it returns an error if the SQL Server instance is unavailable or a string array of the database names that are NOT "online" if databases are not ready.

The purpose of this function is to assure that all databases may be acted upon prior to proceeding with any database Pre-Processing rather than discovering a database that can't be taken offline during the Pre-Processing phase.  The Pre-Processing deals with one database at a time, so this function prevents the situation where databases are taken offline in turn until the process encounters a database that can't be taken offline.  In that case, some databases would be offline while others would still be online.  This function prevents that eventuality.

#### __Parameter__
- DestServer<br>
    This is the name of the server that will receive the snap mount.

- Databases<br>
    This parameter is an array of string of database names that should be checked.

- Silent<br>
    This parameter suppresses any output to the display.

- CheckInstanceOnly<br>
    This parameter prevents databases from being checked resulting in only the Instance availability being checked.

[Top](#phautil)
___
### *Write-CenterBanner*
#### __Description__
This function accepts text to display and places it in the center of a banner of text characterized by an upper margin of -PadCharacter characters.  The text to display on the second line is centered in a field of -PadCharacter characters and a lower margin similar to the upper margin completes the banner.

Example:<br>
```SQLServer
--=====================================================================================
--=============================      sdc-dw2: Logins      =============================
--=====================================================================================
```

#### __Parameter__
- TextToDisplay<br>
    This is the text to be displayed within tha banner.

- PadCharacter<br>
    This is the character the manner margins are constructed from.  It defaults to an equal sign "=" but can be anything you'd like

- FieldLength<br>
    This is the maximum width of the banner.  It default so 84 characters but can be anything you like.

- TextPadCharacher<br>
    This is a character to pad the text to be displayed with.  It generally consists of spaces and pads the text from the banner padding.

- TextPadLength<br>
    This is the length of padding to be placed around the text to display.  It generally consists of spaces and pads the text from the banner padding.

- CommentString<br>
    If this banner will be used within generated script such as T-SQL or PowerShell script, it should be placed in a comment.  This string contains the character(s) that signal a comment in the target language.  For example in T-SQL the string would be "--", or in PowerShell, it would be "#"

[Top](#phautil)
___
## PhaUtil JSON File
The following configurtion items can be found in the PhaUtil.json file.<br>
Note: Elements preceded by a period "." are instantiated as global variables but without the prepended period in the variable name.  Otherwise, they are instantiated as local variables within the module.<br>
Example: .SqlCmdParms is instantiated as $global:SqlCmdParms.

|Variable                 | Description                                                                                                              |
|-------------------------|--------------------------------------------------------------------------------------------------------------------------|
| CmsServer               | This is the SQL Server instance name for the Central Management Server (CMS)                                             |
| DsiServer               | This is the SQL Server instance hosting the DSI database                                                                 |
| DbaDbServer             | This is the SQL Server instance hosting the DBA_db database                                                              |
| MdsServer               | This is the SQL Server instance hosting the MDS database                                                                 |
| CMS_Database            | This is the name of the CMS database (usually "msdb")                                                                    |
| DSI_Database            | This is the name of the DSI database (usually "DSI")                                                                     |
| DBA_db_Database         | This is the name of the DBA_db database (usually "DBA_db")                                                               |
| MDS_Database            | This is the name of the MDS database (usually "MDS")                                                                     |
| PSRepo_Location         | This is the file system location for the PacificSource PowerShell repository                                             |
| PSRepo_Name             | This is the name of the PacificSource PowerShell repository (Currently PSREPO)                                           |
| ARS_Log_Instance        | This is the SQL Server instance hosting the database containing the "ars_registry" table                                 |
| ARS_Log_Database        | This is the name of the database containing the "ars_registry" table                                                     |
| BlitzAllFileName        | This is the name of the file that installs all of Blitz First Responder Kit                                              |
| BlitzNoQueryFileName    | This is the name of the file that installs only the basic Blitz First Responder Kit                                      |
| BlitzWithQueryFileName  | This is the name of the file that installs the Blitz First Responder Kit with Query Store                                |
| EnvironmentRefreshDB    | This is the name of the database containing the ARS objects and procedures. Usually "admin"                              |
| AdminOjbectsToDeploy    | This is an array of systems to install when creating a new "admin" database.  Accepted values are:<br>
ManagementObjects, WhoIsActive, Blitz, and ARS |
| DSI_XTRA_Environments   | This is an array of environments supported by DSI that are other than DEV, QA and PROD                                   |
| .SqlCmdParms            | This is an array of any additional parameters to pass to the Invoke-Sqlcmd cmdlet                                        |
|                         |                                                                                                                          |


[Top](#phautil)
___
### *Create The ARS Registry Log Table*
The ARS Registry Log table (used by Get-PsArsRegistry) can be created manually by executing the following T-SQL script in the target database.  If not created manually, the Get-PsArsRegistry function will create it the first time it's executed with the -ExportToTable parameter:
``` SQL
set ansi_nulls on
go

set quoted_identifier on
go

create table [dbo].[ars_registry](
	[instance] [nvarchar](128) not null,
	[edition] [varchar](10) not null,
	[Id] [int] not null,
	[CreateDate] [datetime] not null,
	[DatabaseName] [varchar](100) not null,
	[NetworkBackupFilePath] [varchar](260) null,
	[RestoreFromServer] [varchar](100) null,
	[RecoveryMode] [varchar](25) not null,
	[LastModDate] [datetime] not null,
	[Active] [bit] not null,
	[SourceDbName] [varchar](100) null,
	[GroupId] [int] not null,
	[WithEncryption] [bit] not null,
	[vendor_cd] [char](2) not null,
	[revision] [datetime] not null,
 constraint [PK_ars_registry] primary key clustered 
(
	[instance] asc,
	[edition] asc,
	[Id] asc
)with (pad_index = off, statistics_norecompute = off, ignore_dup_key = off, allow_row_locks = on, allow_page_locks = on, optimize_for_sequential_key = off) on [PRIMARY]
) on [PRIMARY]
go

alter authorization on [dbo].[ars_registry] to  schema owner 
go

alter table [dbo].[ars_registry] add  default ((1)) for [GroupId]
go

```
[Top](#phautil)
___
