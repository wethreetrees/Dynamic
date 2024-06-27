<#
.SYNOPSIS
    Writes a greeting to the console.
.DESCRIPTION
    Writes a greeting to the console.
.EXAMPLE
    Write-HelloBegin
    Hello, World!
.COMPONENT
    WriteHello
.INPUTS
    None
.OUTPUTS
    System.String
.NOTES
    This is a test function for the dynamic parameter resolution module.
.LINK
    https://github.com/wethreetrees/Dynamic
.ROLE
    Write
.PARAMETER NAME
    The name of the person to greet
#>

function Write-HelloBegin {
    [CmdletBinding()]
    param (
        [Parameter()]
        $Name = 'World'
    )

    begin {
        Write-Output "Hello, $Name!"
    }

}