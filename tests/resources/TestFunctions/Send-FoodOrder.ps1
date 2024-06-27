<#
.SYNOPSIS
    Sends a food order to the kitchen.
.DESCRIPTION
    Sends a food order to the kitchen.
.EXAMPLE
    Send-FoodOrder -Type sandwich -Bread wheat
    Ordering a wheat bread sandwich
.EXAMPLE
    Send-FoodOrder -Type pizza -Crust thin
    Ordering a thin crust pizza
.PARAMETER Type
    The type of food to order.
.PARAMETER Bread
    The type of bread to use for a sandwich.
.PARAMETER Crust
    The type of crust to use for a pizza.
.OUTPUTS
    System.String
.NOTES
    This is a test function for the dynamic parameter resolution module.
#>

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