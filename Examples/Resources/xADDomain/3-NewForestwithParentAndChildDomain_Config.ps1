<#PSScriptInfo
.VERSION 1.0
.GUID aad067ec-0e7a-4a41-874d-432a3ff73437
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
        This configuration will create a domain, and then create a child domain on
        another node.
#>

Configuration NewForestwithParentAndChildDomain_Config
{
    param
    (
        [Parameter(Mandatory)]
        [pscredential]$safemodeAdministratorCred,

        [Parameter(Mandatory)]
        [pscredential]$domainCred,

        [Parameter(Mandatory)]
        [pscredential]$DNSDelegationCred,

        [Parameter(Mandatory)]
        [pscredential]$NewADUserCred
    )

    Import-DscResource -ModuleName xActiveDirectory

    Node $AllNodes.Where{ $_.Role -eq "Parent DC" }.Nodename
    {
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name   = "AD-Domain-Services"
        }

        xADDomain FirstDS
        {
            DomainName                    = $Node.DomainName
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            DnsDelegationCredential       = $DNSDelegationCred
            DependsOn                     = "[WindowsFeature]ADDSInstall"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName           = $Node.DomainName
            DomainUserCredential = $domainCred
            RetryCount           = $Node.RetryCount
            RetryIntervalSec     = $Node.RetryIntervalSec
            DependsOn            = "[xADDomain]FirstDS"
        }

        xADUser FirstUser
        {
            DomainName                    = $Node.DomainName
            DomainAdministratorCredential = $domaincred
            UserName                      = "dummy"
            Password                      = $NewADUserCred
            Ensure                        = "Present"
            DependsOn                     = "[xWaitForADDomain]DscForestWait"
        }

    }

    Node $AllNodes.Where{ $_.Role -eq "Child DC" }.Nodename
    {
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name   = "AD-Domain-Services"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName           = $Node.ParentDomainName
            DomainUserCredential = $domainCred
            RetryCount           = $Node.RetryCount
            RetryIntervalSec     = $Node.RetryIntervalSec
            DependsOn            = "[WindowsFeature]ADDSInstall"
        }

        xADDomain ChildDS
        {
            DomainName                    = $Node.DomainName
            ParentDomainName              = $Node.ParentDomainName
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            DependsOn                     = "[xWaitForADDomain]DscForestWait"
        }
    }
}

$ConfigurationData = @{

    AllNodes = @(
        @{
            Nodename         = "dsc-testNode1"
            Role             = "Parent DC"
            DomainName       = "dsc-test.contoso.com"
            CertificateFile  = "C:\publicKeys\targetNode.cer"
            Thumbprint       = "AC23EA3A9E291A75757A556D0B71CBBF8C4F6FD8"
            RetryCount       = 50
            RetryIntervalSec = 30
        },

        @{
            Nodename         = "dsc-testNode2"
            Role             = "Child DC"
            DomainName       = "dsc-child"
            ParentDomainName = "dsc-test.contoso.com"
            CertificateFile  = "C:\publicKeys\targetNode.cer"
            Thumbprint       = "AC23EA3A9E291A75757A556D0B71CBBF8C4F6FD8"
            RetryCount       = 50
            RetryIntervalSec = 30
        }
    )
}
