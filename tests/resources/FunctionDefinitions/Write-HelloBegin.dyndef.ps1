<#
.COMPONENT
    WriteHello
.DESCRIPTION
    Writes a greeting to the console.
.EXAMPLE
    Write-HelloBegin
    Hello, World!
.INPUTS
    None
.LINK
    https://github.com/wethreetrees/Dynamic
.NOTES
    This is a test function for the dynamic parameter resolution module.
.OUTPUTS
    System.String
.PARAMETER NAME
    The name of the person to greet
.ROLE
    Write
.SYNOPSIS
    Writes a greeting to the console.
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