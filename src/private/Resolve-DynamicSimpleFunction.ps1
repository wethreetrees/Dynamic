function Resolve-DynamicSimpleFunction {
    <#
        .SYNOPSIS
            Generates a scriptblock reflecting the original function definition

        .DESCRIPTION
            Resolve-DynamicSimpleFunction performs no modification of the provided function's
            definition. It is used to handle cases where functions are being processed in bulk
            and a function is encountered that does not have cmdlet binding enabled.

            Without cmdlet binding, any [Dynamic()] decorated parameters are not able to be
            resolved to their full definitions.

        .EXAMPLE
            ```powershell
            function Hello {
                Write-Output "Hello"
            }
            Resolve-DynamicSimpleFunction -FunctionInfo (Get-Command -Name Hello)
            ```

            Returns the original function definition for the 'Hello' function, as a scriptblock

        .OUTPUTS
            scriptblock
    #>

    [CmdletBinding()]
    param (
        # FunctionInfo for function without cmdlet binding
        [Parameter(Mandatory)]
        [System.Management.Automation.FunctionInfo]$FunctionInfo
    )

    process {
        try {
            $stringBuilder = New-Object System.Text.StringBuilder
            $null = $stringBuilder.Append("function $($FunctionInfo.Name) {")
            $null = $stringBuilder.Append($FunctionInfo.Definition)
            $null = $stringBuilder.Append('}')
            return [ScriptBlock]::Create($stringBuilder)
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}