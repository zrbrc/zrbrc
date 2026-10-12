<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
###Requires -RunAsAdministrator

$servers = @(
    'hostuvms02domain.com'
    'host04domain.com'
    'hosteligodb03domain.com',
    'hosteligap03domain.com',
    'host3demap01domain.com',
    'host3demap02domain.com',
    'hostdecsswb01domain.com'
    'hostdecsswb02domain.com',
    'hostdecssap03domain.com',
    'hostdecssap04domain.com',
    'hostdecsswb01domain.com',
    'hostdecssap03domain.com',
    'hostuvms01domain.com',
    'hostsftp01domain.com',
    'hostdecssfp01domain.com',
    'hostdecssfp01domain.com',
    'hosteligap35domain.com'
)

$servers = $servers | Sort-Object -Unique

foreach ($server in $servers) {
    "`nStarting {0} ..." -f $server
    
    # copy jdbc to server
    Copy-Item -Path 'D:\Setup\sqljdbc_xx.xx.xx.xx_enu\sqljdbc_12.4' -Destination "\\$server\c$\temp" -Recurse -Force

    Invoke-Command -ComputerName $server -ScriptBlock {
        try {
            $ErrorActionPreference = 'Stop'
        
            # get all installed $U values.xml
            $ValuesXMLs = Get-ChildItem HKLM:\SYSTEM\CurrentControlSet\Services\DHS*IO*\Parameters | Get-ItemPropertyValue -Name Values

            # we do a loop in case there are multiple instances installed (dont do anymore)
            foreach ($file in $ValuesXMLs) {
                "checking values.xml: {0}" -f $file

                # find the current location of the jdbc files so we can put the new in the same place
                $xml = Select-Xml -Path $file -XPath '//values/duas'
            
                # get current path of jdbc to know where to copy to new jdbc to
                $old_jdbc_filepath = ($xml.Node.var | Where-Object { $_.id -eq 'MSSQL_DRIVER_PATH' }).'#text'

                if ($old_jdbc_filepath -eq $null -or $old_jdbc_filepath -eq '') { "this server isnt using jdbc"; continue;}

                # jdbc file is 3 levels deep, going up 3 to get path
                $jdbc_folder = $old_jdbc_filepath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent

                Copy-Item 'C:\Temp\sqljdbc_12.4' -Destination $jdbc_folder -Recurse -Force

                $new_jdbc_filepath = $jdbc_folder + '\sqljdbc_12.4\enu\jars\mssql-jdbc-12.4.2.jre11.jar'
                
                if (!(Test-Path $new_jdbc_filepath)) { throw "path to jdbc.jar invalid" }
                "jdbc files copied $new_jdbc_filepath"
                
                "updating values.xml"
                $replace = '<var id="MSSQL_DRIVER_PATH">' + $new_jdbc_filepath + '</var>'
                (Get-Content -Path $file -Raw) -replace '<var id="MSSQL_DRIVER_PATH">.+</var>', $replace  | Set-Content -Path $xml

                "values.xml updated with new jar location"

                # restart GSI service
                Get-Service -DisplayName "Univer*_IO_*" | Restart-Service -PassThru
            }
        }
        catch {
            "something happened with {0}" -f $server
            continue
        }
    }

}
