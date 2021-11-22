function Add-DynamicFunctionDynamicParamBlock {
    [CmdletBinding()]
    param (
        # StringBuilder in which to add the param block placeholder
        [Parameter(Mandatory)]
        [System.Text.StringBuilder]$StringBuilder,

        # Dynamic parameter ParameterAst object(s)
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.Language.ParameterAst[]]$ParameterAst,

        # Default values for the [Dynamic()] parameters, if any
        [Parameter()]
        [hashtable]$DefaultValueTable = @{}
    )

    begin {
        try {
            $commonParameters = @(
                'Verbose',
                'Debug',
                'ErrorAction',
                'WarningAction',
                'InformationAction',
                'ErrorVariable',
                'WarningVariable',
                'InformationVariable',
                'OutVariable',
                'OutBuffer',
                'PipelineVariable'
            )

            $null = $StringBuilder.AppendLine('    dynamicparam {')
            $null = $StringBuilder.AppendLine('        # create container for all dynamically created parameters:')
            $null = $StringBuilder.AppendLine('        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()')
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        try {
            $ParameterAst | ForEach-Object {
                $parameter = $_

                $dynamicAttribute = Get-DynamicFunctionParameterDynamicAttribute -ParameterAst $parameter
                $condition = Get-DynamicFunctionParameterDynamicAttributeCondition -AttributeAst $dynamicAttribute

                $parameterName = $parameter.Name.VariablePath.UserPath

                $null = $StringBuilder.AppendLine()
                $null = $StringBuilder.AppendLine('        <#')
                $null = $StringBuilder.AppendLine("            region Start Parameter -$parameterName ####")
                $null = $StringBuilder.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                $null = $StringBuilder.AppendLine('        #>')
                $null = $StringBuilder.AppendLine()
                if ($condition) {
                    $null = $StringBuilder.AppendLine("        if ($condition) {")
                    $padLeft = '    '
                } else {
                    $padLeft = $null
                }
                $null = $StringBuilder.AppendLine("$padLeft        # create container storing all attributes for parameter -$parameterName")
                $null = $StringBuilder.AppendLine("$padLeft        `$attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()")
                $null = $StringBuilder.AppendLine()

                $conflicts = $commonParameters -like "$parameterName*"
                if ($conflicts.Count -gt 0) {
                    throw ('Parameter -{0} conflicts with built-in parameters {1}. Rename -{0}.' -f $parameterName, ('-' + ($conflicts -join ', -')))
                }

                $defaultValue = $parameter.DefaultValue.Extent.Text

                # Set the default type to Object, in case there is no type defined
                $theType = 'Object'

                $hasParameterAttribute = $false

                $parameter.Attributes | ForEach-Object {
                    $attribute = $_
                    switch ($attribute.GetType().FullName) {
                        'System.Management.Automation.Language.TypeConstraintAst' {
                            $theType = $attribute.TypeName.FullName
                        }
                        'System.Management.Automation.Language.AttributeAst' {
                            $typeName = $attribute.TypeName.FullName
                            if ($typename -ne 'Dynamic') {
                                if (!$hasParameterAttribute -and $typename -eq 'Parameter') { $hasParameterAttribute = $true }
                                [string]$positionals = $attribute.PositionalArguments.Extent.Text -join ', '
                                $null = $StringBuilder.AppendLine(("$padLeft        # Define attribute [{0}()]:" -f $attribute.TypeName.FullName))
                                $null = $StringBuilder.AppendLine(("$padLeft        `$attrib = [{0}]::new({1})" -f $attribute.TypeName.FullName, $positionals))
                                $attribute.NamedArguments | ForEach-Object {
                                    $namedAttributeExpression = $_.ToString()
                                    if ($_.ExpressionOmitted)
                                    { $namedAttributeExpression += ' = $true' }

                                    $null = $StringBuilder.AppendLine(("$padLeft        `$attrib.{0}" -f $namedAttributeExpression))
                                }
                                $null = $StringBuilder.AppendLine("$padLeft        `$attributeCollection.Add(`$attrib)")
                                $null = $StringBuilder.AppendLine()
                            }
                        }
                        default {
                            Write-Warning "Unexpected Type: $attribute"
                        }
                    }
                }

                if (!$hasParameterAttribute) {
                    $null = $StringBuilder.AppendLine("$padLeft        # Define attribute [Parameter()]")
                    $null = $StringBuilder.AppendLine("$padLeft        `$attrib = [Parameter]::new()")
                    $null = $StringBuilder.AppendLine("$padLeft        `$attributeCollection.Add(`$attrib)")
                    $null = $StringBuilder.AppendLine()
                }
                $null = $StringBuilder.AppendLine("$padLeft        # compose dynamic parameter:")
                $null = $StringBuilder.AppendLine("$padLeft        `$dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('$parameterName', [$theType], `$attributeCollection)")

                # store parameter default value:
                if ($null -ne $defaultValue) {
                    $DefaultValueTable[$parameterName] = $defaultValue
                }
                $null = $StringBuilder.AppendLine()
                $null = $StringBuilder.AppendLine("$padLeft        # add parameter to parameter collection:")
                $null = $StringBuilder.AppendLine("$padLeft        `$paramDictionary.Add('$parameterName', `$dynParam)")
                if ($condition) {
                    $null = $StringBuilder.AppendLine('        }')
                }
                $null = $StringBuilder.AppendLine()
                $null = $StringBuilder.AppendLine('        <#')
                $null = $StringBuilder.AppendLine("            endregion End Parameter -$($parameterName) ####")
                $null = $StringBuilder.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                $null = $StringBuilder.AppendLine('        #>')
                $null = $StringBuilder.AppendLine()
            }
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    end {
        try {
            $null = $StringBuilder.AppendLine("        # return dynamic parameter collection:")
            $null = $StringBuilder.AppendLine("        `$paramDictionary")
            $null = $StringBuilder.AppendLine("    }")
            $null = $StringBuilder.AppendLine()
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}