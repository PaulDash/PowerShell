#           _          _
#        __| |____ ___| |__
#       / _  |__  / __| '_ \           Script: '1.09 ServiceTools SIMPLE.psm1'
#      | (_| |(_| \__ \ | | |          Author: Paul 'Dash'
#       \__,_\__,_|___/_| |_(_)        E-mail: paul@dash.training
#       T  R  A  I  N  I  N  G


# MAKING MODULES
#################################################
# This is a demo of creating a simple script module# Remember to save this file:# - in a Modules path (one of $env:PSModulePath)# - in a separate folder# - with a name like the name of the folder# - with the .psm1 extension


function Get-ServiceStartInfo {
    <#
    .SYNOPSIS
    Gets information about how a service is being started.
    .DESCRIPTION
    More text here.... someday.
    .PARAMETER Name
    Defines the name of the service to retrieve.
    .EXAMPLE
    ServiceStartInfo.ps1 -Name spooler
    Gets information about the Print Spooler service from the local computer.
    #>

    [cmdletBinding()]
                    param(
    [Parameter(Mandatory=$true)]
    [string]$Name,

    # The computer to retrieve services from.
    [string[]]$ComputerName = 'localhost'
    )

    Write-Debug "Looking for service '$Name' on computer '$ComputerName'."

    Get-CimInstance -ClassName Win32_Service |
    Where-Object Name -eq $Name |
    Select-Object Name,DisplayName,State,StartMode,StartName
} # END function