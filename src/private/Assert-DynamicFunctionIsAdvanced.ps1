function Assert-DynamicFunctionIsAdvanced {
    <#
        .SYNOPSIS
            Asserts that the function has cmdlet binding enabled, through the [CmdletBinding()] attribute

        .DESCRIPTION
            Assert-DynamicFunctionIsAdvanced accepts a FunctionInfo object and checks the CmdletBinding
            property to determin if it is an advanced function

        .EXAMPLE
            Assert-DynamicFunctionIsAdvanced -FunctionInfo (Get-Command -Name Resolve-DynamicFunctionDefinition)

            Checks if 'Resolve-DynamicFunctionDefinition' is an advnaced function

        .OUTPUTS
            bool
    #>

    [CmdletBinding()]
    param (
        # FunctionInfo object
        [Parameter(Mandatory)]
        [System.Management.Automation.FunctionInfo]$FunctionInfo
    )

    process {
        try {
            return $FunctionInfo.CmdletBinding
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}