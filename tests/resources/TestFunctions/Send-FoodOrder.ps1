function Send-FoodOrder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet(
            'sandwich',
            'pizza'
        )]
        [string]$Type,

        [Parameter()]
        [Dynamic({
            $PSBoundParameters['Type'] = 'sandwich'
        })]
        [ValidateSet(
            'white',
            'wheat',
            'rye',
            'pumpernickel'
        )]
        [string]$Bread = 'white',

        [Parameter()]
        [Dynamic({
            $PSBoundParameters['Type'] = 'pizza'
        })]
        [ValidateSet(
            'hand-tossed',
            'thin',
            'pan'
        )]
        [string]$Crust = 'hand-tossed'
    )

    process {
        switch ($Type) {
            'sandwich' { Write-Output "Ordering a $Bread bread sandwich" }
            'pizza'    { Write-Output "Ordering a $Crust crust pizza" }
        }
    }

}