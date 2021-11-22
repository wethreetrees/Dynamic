function Write-HiForce {
    param (
        $Name = 'World',

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
        Write-Output "Hi, $Name!"
        if ($Planet) {
            Write-Output "Welcome to $Planet!"
        }
    }

}