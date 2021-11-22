function Write-HelloEndPipeline {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        $Name = 'World',

        [Parameter(Mandatory, ValueFromPipeline)]
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

    end {
        Write-Output "Hello, $Name!"
        if ($Planet) {
            Write-Output "Welcome to $Planet!"
        }
    }

}