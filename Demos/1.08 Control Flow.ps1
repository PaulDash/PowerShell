﻿#
#        _| _ __|_           Script:  '1.08 Control Flow.ps1' 
#       (_|(_|_)| ) .        Author:  Paul 'Dash'
#      t r a i n i n g       Contact: paul@dash.training
#                            Created: 2019-09-20
#                            Mod on:  2020-03-03 : commented code
#


# CONTROL FLOW EXAMPLES

## LOOPS

### FOREACH
# In cmdlet form, this typically takes input from the pipeline.
# The special placeholder variable ($_ or $PSItem) is used to represent each individual passed object.
Get-Service X* | ForEach-Object { Write-Host -f White -b DarkCyan $_.DisplayName }

# In statement form, a new variable and a collection to iterate are enclosed parenthesis,
# and the new variable is used in the code block to represent each individual passed object.
# If passed through a variable, traditionally the collection is named as a plural and
# the new variable representing each object is named as singular.
$ManyServices = Get-Service X*
foreach ($OneService in $ManyServices) {
    Write-Host -f White -b DarkCyan $OneService.DisplayName
}


### FOR
# Like in many other languages, PowerShell has a 'For loop'.
# The parenthesis hold the: initial counter value,
#                           condition for running the loop,
#                           operation to be performed on the counter each time the loop runs.
# Traditionally, counters are named i, j, k.
# This example counts from 1 to 10:
for ($i = 1; $i -lt 11; $i++) { 
    Write-Host -f White -b DarkCyan $i
}


## WHILE AND UNTIL
# Constructs that are similar to each other and loop, checking a condition to quit.
# Difference is in WHEN the condition is checked and whether we expect a value of TRUE or FALSE.

# Checks condition at the beginning. Condition has to be FALSE to quit.
while ((Read-Host -Prompt 'Type "Q" to quit') -ne 'Q') {
    'Not quitting yet'
}

# Checks condition after first execution of script block. Condition has to be FALSE to quit.
do {
    'Not quitting yet'
} while ((Read-Host -Prompt 'Type "Q" to quit') -ne 'Q')

# Checks condition after first execution of script block. Condition has to be TRUE to quit.
do {
    'Not quitting yet'
} until ((Read-Host -Prompt 'Type "Q" to quit') -eq 'Q')


## CONDITIONAL STATEMENTS

### IF
# Like in other languages. Can combine multiple (even different) conditions with 'elseif'.
# Make sure the most specific case is checked first. Only single match is made.
cls
$ComputerName = Read-Host -Prompt 'Type a computer name'
if ($ComputerName -eq 'LON-DC1') {
    'The DC in London'
} elseif ($ComputerName -like "*CL?") {
    'The client'
} else {
    'Unknown computer'
}


# SWITCH (also called CASE) STATEMENT
# Compares input from parenthesis against values on subsequent lines.
# Multiple matches are allowed, so a 'break' statement can be used to exit the switch.
# Does exact comparisons by default, but can also use wildcards or Regular Expressions.
cls
switch -Wildcard (Read-Host -Prompt 'Type a computer name') {
    '*DC*' { 'The DOMAIN CONTROLLER'}
    '*CL*' { 'The CLIENT'}
    '*LON*'{ 'in London'; BREAK }
    '*OSL*'{ 'in Oslo'   }
    '*WDC*'{ 'in Washington, District of Columbia' }
    default { 'UNKNOWN'}
}
