#           _          _       
#        __| |____ ___| |__    
#       / _  |__  / __| '_ \           Script: 'DashTools.ps1'
#      | (_| |(_| \__ \ | | |          Author: Paul 'Dash'
#       \__,_\__,_|___/_| |_(_)        E-mail: paul@dash.training
#       T  R  A  I  N  I  N  G 


break # STOP RUNNING
      # Either save this as a module (.psm1) in the proper location and
      # remove the above line or copy only the functions that you need
      # into your own script / profile / module.


function Get-LoremIpsum {
<#
.SYNOPSIS
Generates placeholder text.
.DESCRIPTION
Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of 
"de Finibus Bonorum et Malorum" (The Extremes of Good and Evil) 
by Cicero, written in 45 BC. This book is a treatise on the theory 
of ethics, very popular during the Renaissance.
.PARAMETER Length
Length, in characters, of the returned text. Maximum is 2048.
#>
	param(
		[parameter(Mandatory=$false)]
        [Int32]$Length = 175
	)
	
	if ($Length -gt 2048) {$Length = 2050}
	
	$LoremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas ultrices accumsan turpis in elementum. Pellentesque dolor risus, molestie a vulputate ac, volutpat eu turpis. Proin rutrum augue vel sapien venenatis vel luctus augue consectetur. Vivamus sagittis lacus a lacus elementum eleifend. Proin molestie dignissim turpis, et posuere diam congue nec. In nunc diam, luctus sed tincidunt id, egestas et magna. Ut ligula nibh, ultrices id venenatis sit amet, adipiscing eget leo. Fusce nec dolor vitae magna mattis molestie. Etiam dictum nisi eu erat convallis a vestibulum ligula sollicitudin. Nam sit amet erat eget ante tempor aliquam vitae in erat. Etiam sit amet iaculis quam. Aenean quis purus ut eros consectetur consectetur vel in orci. Nulla facilisi. Morbi sem lectus, pretium at dictum feugiat, pretium nec massa. Aenean justo erat, scelerisque sed accumsan sit amet, varius vitae enim. Pellentesque tincidunt venenatis diam nec iaculis. Etiam consequat, ligula sed ullamcorper blandit, sapien velit mattis purus, quis tincidunt velit sem pharetra lorem. Quisque et dolor velit. Sed accumsan sapien sit amet leo molestie hendrerit tincidunt arcu iaculis. Suspendisse pretium orci tristique augue facilisis hendrerit. Nullam iaculis augue sed tortor auctor at vestibulum eros porta. Proin elementum metus eu dui ultrices vitae ornare enim fringilla. Aliquam erat volutpat. Suspendisse blandit, turpis id pulvinar laoreet, lorem enim tincidunt mi, ac bibendum odio felis et nunc. Cras tempus, est id placerat dapibus, quam risus mattis lectus, sed dignissim nisl justo quis sapien. Donec in adipiscing justo. Vestibulum lacus velit, placerat sit amet vulputate non, sagittis at elit. Proin sit amet lacus vel urna rhoncus accumsan vitae consequat lacus. In vestibulum sodales felis, nec egestas mauris euismod interdum. Aliquam ut ligula non leo convallis mattis a nec turpis. Maecenas lacinia elit et sapien imperdiet viverra in vitae mi. Curabitur vitae mauris eu leo convallis mattis ac et augue. Phasellus viverra tincidunt nunc sed."
	
	Write-Output $LoremIpsum.Substring(0,$Length)
}


<#
.SYNOPSIS
Synthesizes speech instead of sending it down the pipeline.
.DESCRIPTION
The Out-Voice cmdlet uses the Speach API to synthesize speach from the incoming objects.

To specify the objects, use the InputObject parameter or pipe an object to Out-Voice. The object must be castable as a string.
.PARAMETER InputObject
Specifies the object that is spoken.
#>
function Out-Voice {
	param(
		[Parameter(ValueFromPipeline=$true)]
	    [System.String]$InputObject	
	)

	BEGIN {
		$Speaker = New-Object -ComObject SAPI.SPVoice
	}
	PROCESS {
		$Speaker.Speak($InputObject) | Out-Null
	}
}

New-Alias -Name Say -Value Out-Voice


<#
.SYNOPSIS
Gets the data types of objects.
.DESCRIPTION
The Get-Type cmdlet gets the data type as reported by a PowerShell object's GetType() method. You can specify one or more objects by piping them to Get-Type.
#>
function Get-Type {
	BEGIN {
		[string[]]$ObjectTypes = $null
	}
	PROCESS {
		$ObjectTypes = $ObjectTypes + $_.GetType()
	}
	END {
		if ($ObjectTypes.Length -eq 1) {
			Write-Output $ObjectTypes[0]
		}
		if ($ObjectTypes.Length -gt 1) {
			Write-Output ($ObjectTypes | Group-Object | Select-Object @{Label='TypeName';Expression={$_.Name}})
		}
	}
}

New-Alias -Name gt -Value Get-Type


# Quick hack to find files with a stream indicating the "IE Security Zone".
# If downloaded from an untrusted zone, these can be unblocked with Unblock-File.
function Get-FileZoneIdentifier {
    if ((Get-Volume -FilePath (Get-Location)).FileSystem -ne 'NTFS') {
        Write-Error -Message 'Streams not supported on file systems other than NTFS'
        break
    }

    Get-ChildItem -File | 
    ForEach-Object {
        try {
            Get-Item -Path $_.FullName -Stream *
        } catch {
            #TODO: Do something later...
        }  } |
    Where-Object Stream -eq 'Zone.Identifier' |
    Select-Object -Property @{Label='Zone';Expression={
        switch ((Get-Content -Stream Zone.Identifier -Path $_.FileName |
                 Select-String -Pattern '(?:\w*)(\d)').Matches[0].Value)
        {
            0 {"Local Machine"}
            1 {"Intranet"}
            2 {"Trusted"}
            3 {"Internet"}
            4 {"Untrusted"}
            default {"unknown"}
        } # End of switch
    } }, FileName # End of Select-Object
}


# uses Data Protection API (DPAPI)
# http://msdn.microsoft.com/en-us/library/ms995355.aspx
function Export-SecureString {
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline=$true)]
        [System.Security.SecureString]$SecureString,
        [parameter(Mandatory=$true)]
        [string]$FilePath
    )

    ConvertFrom-SecureString -SecureString $SecureString | Out-File -FilePath $FilePath
}


function Import-SecureString {
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline=$true)]
        [System.Security.SecureString]$SecureString,
        [parameter(Mandatory=$true)]
        [string]$FilePath
    )

    Get-Content -Path $FilePath | ConvertTo-SecureString | Write-Output
}


# from http://blogs.msdn.com/b/besidethepoint/archive/2010/09/21/decrypt-secure-strings-in-powershell.aspx
function Unprotect-SecureString {
    param(
        [Parameter(ValueFromPipeline=$true,Mandatory=$true,Position=0)]
        [System.Security.SecureString]
        $InputObject
    )

    $marshal = [System.Runtime.InteropServices.Marshal]
    $ptr = $marshal::SecureStringToBSTR( $InputObject )
    $str = $marshal::PtrToStringBSTR( $ptr )
    $marshal::ZeroFreeBSTR( $ptr )
    Write-Output $str
}


<#
.SYNOPSIS
Retrieves the full type name of the latest error's exception class.
.DESCRIPTION
Get-LatestErrorType is useful when writing Catch blocks as it shows the full name of the exception class of the latest error.

To use, perform an operation that results in an error. Immediately after, execute Get-LatestErrorType.
#>
function Get-LatestErrorType {
    $global:error[0].Exception.GetType().FullName
}


<#
.SYNOPSIS
Tool to find which parameters are mandatory for a cmdlet
.NOTES
# Thank you, Stian, for making me write this.
#>
function Get-RequiredParameter {
    param(
        [string]$Name
    )

    (Get-Help $Name -Full).parameters.parameter |
    Where-Object required -eq 'true' |
    Select-Object Name,ParameterSetName
}


<#
.SYNOPSIS
Lists all WMI namespaces available on this system.
#>
function Get-AllWMINamespaces {
    (Get-WmiObject -Namespace root -List -Recurse |
    Select-Object -ExpandProperty __NAMESPACE ).ToLower() |
    Select-Object -Unique |
    Sort-Object

    # Another option:
    # gwmi -Namespace root -Class __namespace -List -Recurse | select -expa __PATH
}

<#
.SYNOPSIS
Runs .NET garbage collection.
#>
function Invoke-GarbageCollection {
    [CmdletBinding()]
    param()

    # MSDN documentation: https://msdn.microsoft.com/en-us/library/system.gc.gettotalmemory
    # GetTotalMemory( bool forceFullCollection )

    $MemBefore = [System.GC]::GetTotalMemory($false)
    [System.GC]::Collect()
    $MemAfter  = [System.GC]::GetTotalMemory($true)

    Write-Verbose ("Saved {0:N0} MB of managed memory." -f (($MemBefore - $MemAfter)/1MB))
}
