function Get-DynamicFunctionCommentBasedHelp {
    [CmdletBinding()]
    param (
        # FunctionInfo object from which to pull comment-based help content
        [Parameter(Mandatory)]
        [System.Management.Automation.FunctionInfo]$FunctionInfo
    )

    process {
        $commentHelpInfo = $FunctionInfo.ScriptBlock.ast.GetHelpContent()
        if ($null -eq $commentHelpInfo.psobject.Properties.value) {
            return $null
        }

        $commentHelpProps = $commentHelpInfo | Get-Member -MemberType Property | Select-Object -ExpandProperty Name

        $sb = [System.Text.StringBuilder]::new()

        $null = $sb.AppendLine('<#')
        foreach ($prop in $commentHelpProps) {
            $propName = $prop.ToUpper()
            switch ($propName) {
                'PARAMETERS' { $propName = 'PARAMETER' }
                'EXAMPLES' { $propName = 'EXAMPLE' }
                'LINKS' { $propName = 'LINK' }
                default {}
            }
            $value = $commentHelpInfo.$prop
            if ($value) {
                if ($value -is [array]) {
                    $value = $value[0]
                }

                if ($value.Keys) {
                    foreach ($key in $value.Keys) {
                        $null = $sb.AppendLine(".$propName $key")
                        $valueLines = $value[$key] -split "`n"
                        foreach ($line in $valueLines) {
                            if (-not [string]::IsNullOrEmpty($line)) {
                                $null = $sb.AppendLine("    $line")
                            }
                        }
                    }
                } else {
                    $null = $sb.AppendLine(".$propName")
                    $valueLines = $value -split "`n"
                    foreach ($line in $valueLines) {
                        if (-not [string]::IsNullOrEmpty($line)) {
                            $null = $sb.AppendLine("    $line")
                        }
                    }
                }
            }
        }
        $null = $sb.AppendLine('#>')
        return $sb.ToString()
    }

}