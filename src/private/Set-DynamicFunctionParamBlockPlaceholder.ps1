function Set-DynamicFunctionParamBlockPlaceholder {
    <#
        .SYNOPSIS
            Replaces the placeholder '##StaticParams##' in the StringBuilder for the Dynamic function

        .DESCRIPTION
            Set-DynamicFunctionParamBlockPlaceholder replaces the placeholder '##StaticParams##' in
            the StringBuilder for the Dynamic function with the static parameters defined in the
            original function definition

        .EXAMPLE
            Set-DynamicFunctionParamBlockPlaceholder -StringBuilder $stringBuilder -ParameterList $parameterList

            Replaces the placeholder '##StaticParams##' in the $stringBuilder object
    #>

    [CmdletBinding()]
    param (
        # StringBuilder in which to add the param block placeholder
        [Parameter(Mandatory)]
        [System.Text.StringBuilder]$StringBuilder,

        # List of static parameter definitons
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Collections.ObjectModel.Collection[string]]$ParameterList
    )

    process {
        try {
            # Format the static parameter definitions to comply with formatting standards
            $staticParams = $ParameterList -join ", `r`n`r`n        "

            # Replace placeholder in the result with the static parameter list
            $null = $StringBuilder.Replace('##StaticParams##', $staticParams)
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}