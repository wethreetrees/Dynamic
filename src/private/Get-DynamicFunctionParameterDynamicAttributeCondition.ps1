function Get-DynamicFunctionParameterDynamicAttributeCondition {
    <#
        .SYNOPSIS
            Get the condition definition for the [Dynamic()] parameter attribute

        .DESCRIPTION
            Get-DynamicFunctionParameterDynamicAttributeCondition gets the condition
            definition for the [Dynamic()] parameter attribute

        .EXAMPLE
            Get-DynamicFunctionParameterDynamicAttributeCondition -ParameterAst $parameterAst

            Get the [Dynamic()] attribute from the provided $parameterAst object

        .OUTPUTS
            string
    #>

    [CmdletBinding()]
    param (
        # AttributeAst object for a function parameter attribute
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.AttributeAst]$AttributeAst
    )

    process {
        try {
            $conditionDefinition = $AttributeAst.PositionalArguments[0].Extent.Text -replace '^{\s*' -replace '\s*}$'
            return $conditionDefinition
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}