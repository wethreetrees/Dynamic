function Write-Hello {
    [CmdletBinding()]
    param (
        [Parameter()]
        $Name = 'World',

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
            Write-Output "Welome to $Planet!"
        }
    }

}