function Add-DynamicFunctionAttribute {
    <#
        .SYNOPSIS
            Adds the function attributes to the provided StringBuilder

        .DESCRIPTION
            Add-DynamicFunctionAttribute adds the function attributes to the provided StringBuilder

        .EXAMPLE
            PS C:\> <example usage>
            Explanation of what the example does

        .NOTES
            General notes
    #>

    [CmdletBinding()]
    param (
        # StringBuilder in which to add the function attribute definitions
        [Parameter(Mandatory)]
        [System.Text.StringBuilder]$StringBuilder,

        # Param() block object
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ParamBlockAst]$ParamBlockAst
    )

    process {
        try {
            foreach ($attribute in $ParamBlockAst.Attributes) {
                $null = $StringBuilder.AppendLine('    ' + $attribute.Extent.Text)
            }
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}