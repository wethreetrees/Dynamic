function Test-DynamicFunctionDefinition {
    <#
        .SYNOPSIS
            Validates a function definition

        .DESCRIPTION
            Test-DynamicFunctionDefinition creates a new scriptblock from the provided $Definition to
            guarantee the code will execute.

        .INPUTS
            string

        .OUTPUTS
            scriptblock

        .EXAMPLE
            Test-DynamicFunctionDefinition -Definition (Get-Command -Name Resolve-DynamicFunctionDefinition).Definition

            Validate the definition of the 'Resolve-DynamicFunctionDefinition function
    #>

    [CmdletBinding()]
    param (
        # Function definition string to validate
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Definition
    )

    process {
        try {
            try {
                return [ScriptBlock]::Create($Definition)
            } catch {
                Write-Verbose $Definition.ToString()
                throw "Function definition is invalid: $_"
            }
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}