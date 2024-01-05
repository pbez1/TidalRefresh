<#
Get the latest backups from the target UNC share ($FolderPath).
#>
function Get-PSLatestBackups {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory = $true)]
        [string] $SystemName
        ,
        [Parameter(Mandatory = $true)]
        [string] $FolderPath
        ,
        [Parameter(Mandatory = $true)]
        [string] $RestoreType 
        )

    # Get the string to match and the extension from the dbname_pattern from the tidal_path table for the restore type.
    Write-Verbose "Getting the list of most recent backups for path: $FolderPath."

    $sql = "select top 1 dbname_pattern from trf.v_tidal_all where path_name = '$($RestoreType.ToLower())' and system_nm = '$SystemName'"
    $db_name_ptrn = $((Invoke-Sqlcmd @sql_parms -ServerInstance $ConfigServer -Database $ConfigDB -Query $sql).dbname_pattern)
    $string_to_match = $($($db_name_ptrn -replace "`<dbname`>", '') -replace '<date[0-9]>', '').Split('.')[0]
    $extension = '.' + $db_name_ptrn.Split('.')[1]

    $all_files = (Get-ChildItem -Path $FolderPath -File `
        | Sort-Object -Property LastWriteTime -Descending) `
        | Where-Object {$($_.Extension).ToLower() -eq $extension -and $($_.Name).ToLower().IndexOf($string_to_match.ToLower()) -ge 0}
    
    $file_paths = @()
    foreach ($file in $all_files) {
        $file_paths += Join-Path -Path $file.DirectoryName -ChildPath $file.Name
        }

    $file_paths
    }
