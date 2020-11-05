#
#        _| _ __|_           Script:  '3.00 ArgumentCompleter.ps1' 
#       (_|(_|_)| ) .        Author:  Paul 'Dash'
#      t r a i n i n g       Contact: paul@dash.training
#                            Created: 2016-12-04
#


# ARGUMENT COMPLETER
# for Intellisense and <Tab> completion

class LetterCompleter : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
        [string]$commandName,
        [string]$parameterName,
        [string]$wordToComplete,
        [System.Management.Automation.Language.CommandAst]$commandAst,
        [System.Collections.IDictionary]$fakeBoundParameters
    ) {   
        return [System.Management.Automation.CompletionResult[]]@(
            foreach ($l in [char[]]'ABCDEFGHIJKLMNOPQRSTUVQXYZ') {

                [System.Management.Automation.CompletionResult]::new(
                    $l,
                    $l,
                    [System.Management.Automation.CompletionResultType]::ParameterValue, "The letter $l"
                ) # end ...CompletionResult
            } # end foreach
        ) # end return
    } # end CompleteArgument
} # end class


function Write-Letter {
    param (
        [ArgumentCompleter([LetterCompleter])]
        [char]$Letter
    )
    Write-Output $Letter
}
