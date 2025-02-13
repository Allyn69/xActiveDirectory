<#PSScriptInfo
.VERSION 1.0
.GUID e7ed876c-7a6b-46d7-bb89-8288680c1691
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT (c) Microsoft Corporation. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/xActiveDirectory/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/xActiveDirectory
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>

#Requires -module xActiveDirectory

<#
    .DESCRIPTION
        This configuration will add an Active Directory organizational unit to the
        domain.
#>

Configuration CreateADOU_Config
{
    Param(
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [System.Boolean]
        $ProtectedFromAccidentalDeletion = $true,

        [ValidateNotNull()]
        [System.String]
        $Description = ''
    )

    Import-DscResource -Module xActiveDirectory

    Node $AllNodes.NodeName
    {
        xADOrganizationalUnit ExampleOU
        {
            Name                            = $Name
            Path                            = $Path
            ProtectedFromAccidentalDeletion = $ProtectedFromAccidentalDeletion
            Description                     = $Description
            Ensure                          = 'Present'
        }
    }
}
