function Add-DynamicFunctionParamBlockPlaceholder {
    <#
        .SYNOPSIS
            Add a placeholder that will be replaced after processing for [Dynamic()] tagged parameters

        .DESCRIPTION
            Add-DynamicFunctionParamBlockPlaceholder adds a placeholder string that will be replaced
            after processing for [Dynamic()] tagged parameters.

            adds:
                param (
                    ##StaticParams##
                )

        .EXAMPLE
            PS C:\> <example usage>
            Explanation of what the example does

        .NOTES
            General notes
    #>

    [CmdletBinding()]
    param (
        # StringBuilder in which to add the param block placeholder
        [Parameter(Mandatory)]
        [System.Text.StringBuilder]$StringBuilder
    )

    process {
        try {
            $null = $StringBuilder.AppendLine('    param (')
            $null = $StringBuilder.AppendLine('        ##StaticParams##')
            $null = $StringBuilder.AppendLine('    )')
            $null = $StringBuilder.AppendLine()
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}