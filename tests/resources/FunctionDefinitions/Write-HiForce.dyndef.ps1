function Write-HiForce {
    [CmdletBinding()]
    param (
        $Name = 'World'
    )

    dynamicparam {
        # create container for all dynamically created parameters:
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        <#
            region Start Parameter -Planet ####
            created programmatically via Resolve-DynamicFunctionDefinition
        #>

        if ($null -eq $PSBoundParameters['Name']) {
            # create container storing all attributes for parameter -Planet
            $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

            # Define attribute [ValidateSet()]:
            $attrib = [ValidateSet]::new('Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune')
            $attributeCollection.Add($attrib)

            # Define attribute [Parameter()]
            $attrib = [Parameter]::new()
            $attributeCollection.Add($attrib)

            # compose dynamic parameter:
            $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('Planet', [string], $attributeCollection)

            # add parameter to parameter collection:
            $paramDictionary.Add('Planet', $dynParam)
        }

        <#
            endregion End Parameter -Planet ####
            created programmatically via Resolve-DynamicFunctionDefinition
        #>

        # return dynamic parameter collection:
        $paramDictionary
    }

    begin {
        <#
            region initialize variables for dynamic parameters
            created programmatically via Resolve-DynamicFunctionDefinition
        #>

        if ($PSBoundParameters.ContainsKey('Planet')) { $Planet = $PSBoundParameters['Planet'] }
        else { $Planet = $null }

        <#
            endregion initialize variables for dynamic parameters
            created programmatically via Resolve-DynamicFunctionDefinition
        #>
    }

    process {
        Write-Output "Hi, $Name!"
        if ($Planet) {
            Write-Output "Welcome to $Planet!"
        }
    }

}