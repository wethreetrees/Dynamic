function Get-DynamicFunctionScriptBlockContent {
    <#
        .SYNOPSIS
            Get the content from a function scriptblock contained within a FunctionInfo object

        .DESCRIPTION
            Get-DynamicFunctionScriptBlockContent extracts the inner content from a FunctionInfo
            object for a specific function scriptblock, e.g. begin, process, or end. The block
            headers will be removed.

            before:
                process {
                    Write-Output "Hello, World!"
                }

            after:
                    Write-Output "Hello, World!"

        .EXAMPLE
            ```powershell
            $functionInfo = Get-Command -Name Resolve-DynamicFunctionDefinition
            Get-DynamicFunctionScriptBlockContent -Name begin -FunctionInfo $functionInfo
            ```

            Get the inner content of the begin block for the Resolve-DynamicFunctionDefinition function

        .OUTPUTS
            string
    #>

    [CmdletBinding()]
    param (
        # Function scriptblock name: begin, process, or end
        [Parameter(Mandatory)]
        [ValidateSet(
            'begin',
            'process',
            'end'
        )]
        [string]$Name,

        # FunctionInfo object from which to pull scriptblock content
        [Parameter(Mandatory)]
        [System.Management.Automation.FunctionInfo]$FunctionInfo
    )

    process {
        try {
            $blockProperty = "$($Name)Block"
            $blockText = $FunctionInfo.ScriptBlock.Ast.Body.$blockProperty.extent.Text
            $content = $blockText -replace "^$($Name)\s?{\s?`n?" -replace '.*}$'
            return $content
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}