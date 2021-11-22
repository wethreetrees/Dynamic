function Get-DynamicFunctionParameterDynamicAttribute {
    <#
        .SYNOPSIS
            Get the [Dynamic()] parameter attribute from the ParameterAst

        .DESCRIPTION
            Get-DynamicFunctionParameterDynamicAttribute gets the [Dynamic()]
            parameter attribute from the ParameterAst, if it is present

        .EXAMPLE
            Get-DynamicFunctionParameterDynamicAttribute -ParameterAst $parameterAst

            Get the [Dynamic()] attribute from the provided $parameterAst object

        .OUTPUTS
            System.Management.Automation.Language.AttributeAst
    #>

    [CmdletBinding()]
    param (
        # ParameterAst object for a function parameter
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ParameterAst]$ParameterAst
    )

    process {
        try {
            $attributeAst = $ParameterAst.Attributes.Where{ $_.TypeName.FullName -eq 'Dynamic' } | Select-Object -First 1
            return $attributeAst
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}