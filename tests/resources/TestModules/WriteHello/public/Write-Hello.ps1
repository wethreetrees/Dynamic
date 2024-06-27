<#
.DESCRIPTION
    A simple function that writes a greeting to the console
.EXAMPLE
    Write-Hello
    Hello, World!
.PARAMETER Name
    The name of the person to greet
#>

function Write-Hello {
    [CmdletBinding()]
    param (
        # The name of the person to greet
        [Parameter()]
        [string]$Name = 'World',

        # The planet to welcome the person to
        [Parameter(Mandatory)]
        [Dynamic({
            $null -eq $PSBoundParameters['Name']
        })]
        [ValidateSet(
            'Mercury',
            'Venus',
            'Earth',
            'Mars',
            'Jupiter',
            'Saturn',
            'Uranus',
            'Neptune'
        )]
        [string]$Planet
    )

    process {
        Write-Output "Hello, $Name!"
        if ($Planet) {
            Write-Output "Welcome to $Planet!"
        }
    }

}
