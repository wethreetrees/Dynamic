function Write-Hello
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        $Name = 'World'
    )

    dynamicparam
    {
        # create container for all dynamically created parameters:
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        <#
            region Start Parameter -Planet ####
            created programmatically via Set-DynamicParameterDefinition
        #>

        if (
            $null -eq $PSBoundParameters['Name']
        ) {
        # create container storing all attributes for parameter -Planet
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        # Define attribute [Parameter()]:
        $attrib = [Parameter]::new()
        $attrib.Mandatory=$true
        $attributeCollection.Add($attrib)

        # Define attribute [ValidateSet()]:
        $attrib = [ValidateSet]::new('Mercury','Venus','Earth','Mars','Jupiter','Saturn','Uranus','Neptune')
        $attributeCollection.Add($attrib)

        # compose dynamic parameter:
        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('Planet',[string],$attributeCollection)

        # add parameter to parameter collection:
        $paramDictionary.Add('Planet',$dynParam)
        }

        <#
            endregion End Parameter -Planet ####
            created programmatically via Set-DynamicParameterDefinition
        #>

        # return dynamic parameter collection:
        $paramDictionary
    }

    begin {
        <#
            region initialize variables for dynamic parameters
            created programmatically via Set-DynamicParameterDefinition
        #>

        if($PSBoundParameters.ContainsKey('Planet')) { $Planet = $PSBoundParameters['Planet'] }
        else { $Planet = $null}

        <#
            endregion initialize variables for dynamic parameters
            created programmatically via Set-DynamicParameterDefinition
        #>
    }

    process {
        Write-Output "Hello, $Name!"
        if ($Planet) {
            Write-Output "Welome to $Planet!"
        }
    }
}

