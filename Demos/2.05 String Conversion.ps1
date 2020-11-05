#
#        _| _ __|_           Script:  '2.05 String Conversion.ps1' 
#       (_|(_|_)| ) .        Author:  Paul 'Dash'
#      t r a i n i n g       Contact: paul@dash.training
#                            Created: 2020-02-12
#


# CONVERTING STRINGS TO OTHER STRINGS
# The setup. Some strings written out to a file
@"
Johnathan.Doe@adatum.com
Jane.Smith@contoso.com
Ola.Nordmann@something.no
Fake.Person@dash.training
"@ | Out-File emails.txt

# Let's see the strings that got produced:
Get-Content .\emails.txt

# We want to get just the first and last name from those e-mail addresses

# First attempt
Get-Content .\emails.txt |
Convert-String -Example "First.Last@domain.com=First Last"

# Almost. This didn't find the last entry.
# Possibly because it had a much longer domain extension.

# Second attempt, with two "examples" for the command to learn from
Get-Content .\emails.txt |
Convert-String -Example "First.Last@domain.com=First Last","First.Last@short.muchlonger=First Last"



# CONVERTING STRINGS TO OBJECTS
# The setup:
$netstat = netstat

# Let's see just the data from that output.
# We don't care about the first 4 lines and want to clean up the leading spaces.
($netstat[4..$netstat.Length]).trim()

# Now just have the system make sense of it by converting to objects.
# You need to tell the cmdlet which "columns" of data it's seeing.
($netstat[4..$netstat.Length]).trim() |
ConvertFrom-String  -PropertyNames Protocol,TO,FROM,State

# ...or you can just use this, as Bror said ;)
Get-NetTCPConnection -State Established,SynSent
