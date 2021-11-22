function Add-DynamicFunctionScriptBlock {
    <#
        .SYNOPSIS
            Adds a function scriptblock definition to the provided StringBuilder

        .DESCRIPTION
            Add-DynamicFunctionScriptBlock adds a full definition to the provided StringBuilder.
            This will handle the appropriate definitions for a begin, process, or end scriptblock.

        .EXAMPLE
            ```powershell
            $stringBuilder = [System.Text.StringBuilder]::new()
            Add-DynamicFunctionScriptBlock -StringBuilder $stringBuilder -Name begin -Content 'Write-Output "$Greeting, $Name' -Parameters "Greeting"
            ```

            Writes a new begin scriptblock definition with the 'Write-Output "$Greeting, $Name' code,
            and including the script scope declarations for the "Greeting" [Dynamic()] parameter
    #>

    [CmdletBinding()]
    param (
        # StringBuilder in which to add the function scriptblock definition
        [Parameter(Mandatory)]
        [System.Text.StringBuilder]$StringBuilder,

        # Name of the function scriptblock: begin, process, or end
        [Parameter(Mandatory)]
        [ValidateSet(
            'begin',
            'process',
            'end'
        )]
        [string]$Name,

        # Original function content for this scriptblock
        [Parameter()]
        [AllowEmptyString()]
        [string]$Content,

        # Dynamic parameters that need to be declared in the script scope and in this scriptblock
        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$Parameter,

        # Default values for the [Dynamic()] parameters, if any
        [Parameter()]
        [hashtable]$DefaultValueTable = @{}
    )

    process {
        try {
            switch ($Name) {
                'begin'   { $templateComment = "initialize variables for dynamic parameters" }
                'process' { $templateComment = "update variables for pipeline bound parameters" }
            }

            $null = $StringBuilder.AppendLine("    $Name {")
            if ($Parameter.Count) {
                $null = $StringBuilder.AppendLine('        <#')
                $null = $StringBuilder.AppendLine("            region $templateComment")
                $null = $StringBuilder.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                $null = $StringBuilder.AppendLine('        #>')
                $null = $StringBuilder.AppendLine()
                foreach ($param in $Parameter) {
                    $null = $StringBuilder.AppendLine(('        if ($PSBoundParameters.ContainsKey(''{0}'')) {{ ${0} = $PSBoundParameters[''{0}''] }}' -f $param))
                    if ($Name -eq 'begin') {
                        if ($DefaultValueTable.ContainsKey($param)) {
                            $null = $StringBuilder.AppendLine(('        else {{ ${0} = {1} }}' -f $param, $DefaultValueTable[$param]))
                        } else {
                            $null = $StringBuilder.AppendLine(('        else {{ ${0} = $null }}' -f $param))
                        }
                    }
                    $null = $StringBuilder.AppendLine()
                }
                $null = $StringBuilder.AppendLine('        <#')
                $null = $StringBuilder.AppendLine("            endregion $templateComment")
                $null = $StringBuilder.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                $null = $StringBuilder.AppendLine('        #>')

                if (-not [string]::IsNullOrWhiteSpace($Content)) {
                    $null = $StringBuilder.AppendLine()
                }
            }
            $null = $StringBuilder.AppendLine("$Content    }")
            $null = $StringBuilder.AppendLine()
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}