#           _          _       
#        __| |____ ___| |__    
#       / _  |__  / __| '_ \           Script: 'Remove-DuplicateModule.ps1'
#      | (_| |(_| \__ \ | | |          Author: Paul 'Dash'
#       \__,_\__,_|___/_| |_(_)        E-mail: paul@dash.training
#       T  R  A  I  N  I  N  G 


[cmdletbinding()]
param()

$Modules = Get-Module -ListAvailable | select Name,Version | sort Name,Version
$DuplicateModules = $Modules | Group-Object Name | ? Count -GT 1
Write-Verbose $DuplicateModules

foreach ($m in $DuplicateModules) {
    $Versions = $m.Group | Sort Version
    for ($i = 0; $i -lt $Versions.Count -1; $i++) {
        New-Object PSCustomObject -Property @{ 'Name'    = $Versions[$i].Name;
                                               'Version' = $Versions[$i].Version }
        Uninstall-Module -Name $Versions[$i].Name -RequiredVersion $Versions[$i].Version -Force | Out-Null
    }
}
