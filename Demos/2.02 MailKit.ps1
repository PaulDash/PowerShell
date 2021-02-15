#
#        _| _ __|_           Script:  '2.02 Send-Mail.ps1' 
#       (_|(_|_)| ) .        Author:  Paul 'Dash'
#      t r a i n i n g       Contact: paul@dash.training
#                            Created: 2021-02-11
#


# E-MAILING
# Uses the MailKit library that replaces System.Net.Mail

# Read the Send-Mail function, the setup requirements, the data structure for
# mail server configuration and examples of function invocation.



# SETUP

# The right assemblies need to be in place for the right Namespaces to be available.
# NuGet in Windows PowerShell seems to have issues. Try the below line with PowerShell 7.
Find-Package -Name 'MimeKit','MailKit','System.Buffers' `
             -Source 'https://www.nuget.org/api/v2' |
Install-Package -Verbose
# Also needs the Unprotect-SecureString function from my DashTools module
# or from http://blogs.msdn.com/b/besidethepoint/archive/2010/09/21/decrypt-secure-strings-in-powershell.aspx


# SERVER DATA

# Store connection parameters in an object like below. May be wise to save this in your Profile.
# The password is encrypted using your Windows session key. It's safe.
$MailConfig = [PSCustomObject][ordered]@{Server='mail.kki.pl';Port=587;Address='';User='pavo@kki.pl';Password=''}
$MailConfig.Address  = $MailConfig.User
$MailConfig.Password = Read-Host -Prompt "Password for user $($MailConfig.User) on server $($MailConfig.Server)" -AsSecureString |
                       ConvertFrom-SecureString



# THE FUNCTION

# Put this in a module.
# Looking for the right assemblies needs fixing. Here the paths are hard-coded
# and appropriate for Windows Powershell. Other paths required for Core.

function Send-Mail {
    <#
    .SYNOPSIS
    Sends an e-mail message.
    .DESCRIPTION
    Theis cmdlet uses the MailKit library to send an e-mail message
    to the specified recipient with the provided title and body.
    .PARAMETER To
    Specifies the addresses to which the mail is sent.
    .PARAMETER Body
    Specifies the body (text content only) of the e-mail message.
    .PARAMETER Subject
    Specifies the subject of the e-mail message. The default value is set to the name of the previously executed command.
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [string[]]$To,

        [parameter(Mandatory=$false)]
        [string]$Subject = "Send-Mail RESULT of $^",

        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$Body
    )

    BEGIN {
        # Load required assemblies
        $RequiredAssemblies = 'MailKit','MimeKit','System.Buffers'
        foreach ($Assembly in $RequiredAssemblies) {
            (Get-Package -ProviderName NuGet -Name $Assembly).Source
        }
        
        # TODO: Change so that paths don't need to be hard-coded
        # TODO: Consider different environment versions
        $PathMailKit = 'C:\Program Files\PackageManagement\NuGet\Packages\MailKit.2.10.1\lib\net48\MailKit.dll'
        $PathMimeKit = 'C:\Program Files\PackageManagement\NuGet\Packages\MimeKit.2.10.1\lib\net48\MimeKit.dll'
        $PathBuffers = 'C:\Program Files\PackageManagement\NuGet\Packages\System.Buffers.4.5.1\lib\net461\System.Buffers.dll'
        [System.Reflection.Assembly]::LoadFile($PathMailKit) > $null
        [System.Reflection.Assembly]::LoadFile($PathMimeKit) > $null
        [System.Reflection.Assembly]::LoadFile($PathBuffers) > $null
        # LoadFile doesn't work on its own. Neither does Add-Type on its own.
        # Doing both works. Why?
        Add-Type -Path $PathMailKit,$PathMailKit,$PathBuffers

        # Create message object
        $Message = New-Object MimeKit.MimeMessage
        # Define From, To, and Subject
        $Message.From.Add($MailConfig.Address)
        foreach ($MailRecipient in $To) {
            $Message.To.Add($MailRecipient)
	    }
        $Message.Subject = $Subject

        # Start constructing message body
        $MessageBody = New-Object MimeKit.BodyBuilder
    }

    PROCESS {
        foreach ($Line in $Body) {
            # Add single line to message body
            $MessageBody.TextBody += ($Line + "`n")
        }
    }

    END {
        # Save the message body
        $Message.Body  = $MessageBody.ToMessageBody()

        # Create mail client
        $SMTP = New-Object MailKit.Net.Smtp.SmtpClient
        # Set TLS to automatically negotiate security
        $SSLAuto = [MailKit.Security.SecureSocketOptions]::Auto

        try {
            # Connect and send
            $SMTP.Connect($MailConfig.Server, $MailConfig.Port, $SSLAuto)
            $SMTP.Authenticate($MailConfig.User, ($MailConfig.Password | ConvertTo-SecureString | Unprotect-SecureString))
            $SMTP.Send($Message)
        } catch {
		    Write-Output "There was a problem sending the e-mail."
	    }

        # Cleanup
        $SMTP.Disconnect($true)
        $SMTP.Dispose()
    } # END END
} # END function



# EXAMPLES
break


