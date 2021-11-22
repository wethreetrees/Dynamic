function Get-DynamicFunctionParamBlockContent {
    <#
        .SYNOPSIS
            Get the function param block contained within a FunctionInfo object

        .DESCRIPTION
            Get-DynamicFunctionScriptBlockContent extracts the param() block
            from a FunctionInfo object.

        .EXAMPLE
            ```powershell
            $functionInfo = Get-Command -Name Resolve-DynamicFunctionDefinition
            Get-DynamicFunctionParamBlockContent -Name begin -FunctionInfo $functionInfo
            ```

            Get the param block for the Resolve-DynamicFunctionDefinition function

        .OUTPUTS
            System.Management.Automation.Language.ParamBlockAst
    #>

    [CmdletBinding()]
    param (
        # FunctionInfo object from which to pull scriptblock content
        [Parameter(Mandatory)]
        [System.Management.Automation.FunctionInfo]$FunctionInfo
    )

    process {
        try {
            return $FunctionInfo.ScriptBlock.ast.Body.ParamBlock[0]
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}