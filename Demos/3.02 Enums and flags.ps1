#Requires -Version 5

#
#        _| _ __|_           Script:  '3.02 Enums and flags.ps1' 
#       (_|(_|_)| ) .        Author:  Paul 'Dash'
#      t r a i n i n g       Contact: paul@dash.training
#                            Created: 2021-03-25
#

# Demo of enumerations and bit flags based on a question about querying AD
break



# QUESTION 1: How do you find users in AD by something in their Canonical Name?

# This filtering works
Get-ADUser -Filter "Name -like 'Test*'" -Properties CanonicalName |
Where-Object {$_.CanonicalName -like "*IT*"}

# This filtering fails
Get-ADUser -Filter "Name -like 'Test*' -and CanonicalName -like '*IT*'" -Properties CanonicalName



# QUESTION 2: Why does the second way fail?

# Let's digress:
# ENUMERATIONS

# This one exists
[System.DayOfWeek]::Friday
[System.DayOfWeek]6

# We can create enumerations ourselves
enum DayOfWeekend {
    Saturday = 1; Sunday = 2
}
[DayOfWeekend]2



# Inspecting the CanonicalName attribute in the Active Directory Schema
$CanonicalNameFlags = Get-ADObject -Filter "Name -eq 'Canonical-Name'" `
                           -SearchBase 'CN=Schema,CN=Configuration,DC=ad,DC=graydaycafe,DC=com' `
                           -Properties * |
                      Select-Object -ExpandProperty 'systemFlags'
# Value is an integer
$CanonicalNameFlags

# Convert to Base2 to see the bits... each representing a bit flag (1 for ON, 0 for OFF)
[System.Convert]::ToString($CanonicalNameFlags, 2)

# Those flags are documented here
# https://docs.microsoft.com/en-us/windows/win32/adschema/a-systemflags#remarks
# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/1e38247d-8234-4273-9de3-bbf313548631

# We can create an enumeration and view the bit values as [flags()]
[flags()]enum SystemFlags {
    NONE                             =         0
    FLAG_ATTR_NOT_REPLICATED         =         1
    FLAG_ATTR_REQ_PARTIAL_SET_MEMBER =         2
    FLAG_ATTR_IS_CONSTRUCTED         =         4
    FLAG_ATTR_IS_OPERATIONAL         =         8
    FLAG_SCHEMA_BASE_OBJECT          =        16
    FLAG_DISALLOW_MOVE_ON_DELETE     =  33554432
    FLAG_DOMAIN_DISALLOW_MOVE        =  67108864
    FLAG_DOMAIN_DISALLOW_RENAME      = 134217728
}

# Which flags does the CanonicalName attribute have?
$CanonicalNameFlags -as [SystemFlags]

# ANSWER:
# Ah, so the Canonical Name is constructed attribute, so a value isn't really held in AD.
# That's why we can't search based on it.
