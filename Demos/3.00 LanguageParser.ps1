#
#        _| _ __|_           Script:  '3.00 LanguageParser.ps1'
#       (_|(_|_)| ) .        Author:  Paul 'Dash'
#      t r a i n i n g       Contact: paul@dash.training
#                            Created: 2022-06-12
#


# LANGUAGE PARSER
# Shows how PowerShell breaks down a command to try to understand it

# What are tokens? Well, these identifiers:
[enum]::GetValues([System.Management.Automation.Language.TokenKind]) | Measure-Object

########### RUN A COMMAND IN HERE
# It doesn't matter whether it works or not.
$APIPA = '169.*'; Get-NetIPAddress -AddressFamily IPv4 -AddressState Deprecated,'Duplicate',"Invalid" |
Where {$_.IPAddress -NotLike $APIPA}


# Gets the previously run command
$ScriptBlock = (Get-History)[-1].CommandLine

# Prepare arrays for the tokens and any errors
$T = @()
$E = @()

# Let's analyze the script block
[System.Management.Automation.Language.Parser]::ParseInput($ScriptBlock, [ref]$T, [ref]$E)

# Show what was parsed
$T

# Make it nicer
$T | Format-Table Text, Kind, TokenFlags