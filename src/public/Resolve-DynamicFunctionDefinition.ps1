$code = @'
using System;
using System.Collections.Generic;
using System.Management.Automation;

    public class DynamicAttribute : System.Attribute
    {
        private ScriptBlock sb;

        public DynamicAttribute(ScriptBlock condition)
        {
            sb = condition;
        }
    }
'@

$null = Add-Type -TypeDefinition $code *>&1

function Resolve-DynamicFunctionDefinition {
    <#
        .SYNOPSIS
            Generates a scriptblock defining an interpreted function based on the provided function info

        .DESCRIPTION
            Module adds a new attribute named [Dynamic()] that can be used to turn static parameters into dynamic parameters.

            The attribute definition will be defined above a standard parameter definition and must contain a scriptblock that
            evaluates truthiness. Resolve-DynamicFunctionDefinition will then interpret the [Dynamic(...)] attributes into standard
            PowerShell dynamic parameter declarations and return back a scriptblock with the new function definition.

            Example Dynamic Parameter Declaration:

                [Dynamic({$OtherParameter -match "(Value1|Value2)"})]
                [Parameter(Mandatory)]
                [string]$Name

        .EXAMPLE
            Resolve-DynamicFunctionDefinition -FunctionInfo Value

            Evaluates function definition for dynamic parameters and returns a new scriptblock containing
            a function definition to properly handle the defined dynamic parameters

        .NOTES
            Inspired in large part by Dr. Tobias Weltner (https://github.com/TobiasPSP/) and his amazing work at https://powershell.one/
    #>

    [CmdletBinding()]
    param
    (
        # # A scriptblock with a param() block. Assign the attribute [Dynamic()] to all parameters that you want to convert to a dynamic parameter.
        # [Parameter(Mandatory, ValueFromPipeline)]
        # [ScriptBlock]$ScriptBlock,

        # Name of the function to be created. Can be anything, should adhere to common Verb-Noun syntax.
        [Parameter(Mandatory)]
        [System.Management.Automation.FunctionInfo]$FunctionInfo
    )

    begin {
        # common parameters
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
    }

    process {
        try {
            # collect generated code:
            [System.Text.StringBuilder]$result = ''

            # store parameter default values:
            $defaultValues = @{}

            # store list of dynamic parameters:
            $dynParamList = [System.Collections.ObjectModel.Collection[string]]::new()

            # store list of static parameters:
            $paramList = [System.Collections.ObjectModel.Collection[string]]::new()

            # store list of pipeline-aware parameters:
            $pipelineAttribs = 'ValueFromPipeline', 'ValueFromPipelineByPropertyName'
            $pipelineParamList = [System.Collections.ObjectModel.Collection[string]]::new()

            # store list of standard parameters:
            $standardParamList = [System.Collections.ObjectModel.Collection[string]]::new()

            $null = $result.AppendLine("function $($FunctionInfo.Name)")
            $null = $result.AppendLine('{')

            if (-not $FunctionInfo.CmdletBinding) {
                Write-Warning "$($FunctionInfo.Name) is not an advanced function, using original function content"

                $null = $result.AppendLine($FunctionInfo.ScriptBlock)
                $null = $result.Append('}')

                return [ScriptBlock]::Create($result)
            }

            # extract the content of the param() block from the submitted scriptblock:
            $param = $FunctionInfo.ScriptBlock.ast.Body.ParamBlock[0]

            # add attributes
            foreach ($_ in $param.Attributes) {
                $null = $result.AppendLine('    ' + $_.Extent.Text)
            }

            $null = $result.AppendLine(@'
    param
    (
        ##StaticParams##
    )

    dynamicparam
    {
        # create container for all dynamically created parameters:
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
'@)

            $param.Parameters | ForEach-Object {
                $parameter = $_

                # check to see if this parameter was decorated with a [Dynamic()] attribute:
                $dynamicAttribute = $parameter.Attributes.Where{ $_.TypeName.FullName -eq 'Dynamic' } | Select-Object -First 1

                # if so, add to dynamic parameters:
                if ($dynamicAttribute) {
                    $condition = $dynamicAttribute.PositionalArguments[0].Extent.Text -replace '^{' -replace '}$'

                    $name = $parameter.Name.VariablePath.UserPath
                    $dynParamList.Add($name)
                    $null = $result.AppendLine()
                    $null = $result.AppendLine('        <#')
                    $null = $result.AppendLine("            region Start Parameter -${name} ####")
                    $null = $result.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                    $null = $result.AppendLine('        #>')
                    $null = $result.AppendLine()
                    if ($condition) {
                        $null = $result.AppendLine("        if ($condition) {")
                    }
                    $null = $result.AppendLine("        # create container storing all attributes for parameter -$name")
                    $null = $result.AppendLine('        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()')
                    $null = $result.AppendLine('')

                    $conflicts = $commonParameters -like "$name*"
                    if ($conflicts.Count -gt 0) {
                        throw ('Parameter -{0} conflicts with built-in parameters {1}. Rename -{0}.' -f $name, ('-' + ($conflicts -join ', -')))
                    }

                    $defaultValue = $parameter.DefaultValue.Extent.Text

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
                                    [string]$positionals = $attribute.PositionalArguments.Extent.Text -join ','
                                    $null = $result.AppendLine(('        # Define attribute [{0}()]:' -f $attribute.TypeName.FullName))
                                    $null = $result.AppendLine(('        $attrib = [{0}]::new({1})' -f $attribute.TypeName.FullName, $positionals))
                                    $attribute.NamedArguments | ForEach-Object {
                                        $namedAttributeExpression = $_.ToString()
                                        if ($_.ExpressionOmitted)
                                        { $namedAttributeExpression += '=$true' }

                                        $null = $result.AppendLine(('        $attrib.{0}' -f $namedAttributeExpression))

                                        # if parameter is pipeline-aware, remember it:
                                        if ($_.ArgumentName -in $pipelineAttribs -and $pipelineParamList.Contains($Name) -eq $false) {
                                            $pipelineParamList.Add($name)
                                        } else {
                                            $standardParamList.Add($name)
                                        }
                                    }
                                    $null = $result.AppendLine('        $attributeCollection.Add($attrib)')
                                    $null = $result.AppendLine('')
                                }
                            }
                            default {
                                Write-Warning "Unexpected Type: $_"
                            }
                        }

                    }
                    if (!$hasParameterAttribute) {
                        $null = $result.AppendLine('        # Define attribute [Parameter()]:')
                        $null = $result.AppendLine('        $attrib = [Parameter]::new()')
                        $null = $result.AppendLine('        $attributeCollection.Add($attrib)')
                        $null = $result.AppendLine('')
                    }
                    $null = $result.AppendLine('        # compose dynamic parameter:')
                    $null = $result.AppendLine(('        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new({0},{1},$attributeCollection)' -f "'$Name'", "[$theType]"))
                    if ($theType -eq 'Object')
                    { Write-Warning ('Parameter -{0} currently is of type [Object]. Using an appropriate type constraint like [string], [int], [datetime] etc in your parameter definition is recommended.' -f $Name) }

                    # store parameter default value:
                    if ($null -ne $defaultValue) {
                        $defaultValues[$name] = $defaultValue
                    }
                    $null = $result.AppendLine()
                    $null = $result.AppendLine('        # add parameter to parameter collection:')
                    $null = $result.AppendLine(('        $paramDictionary.Add({0},$dynParam)' -f "'$Name'"))
                    if ($condition) {
                        $null = $result.AppendLine('        }')
                    }
                    $null = $result.AppendLine()
                    $null = $result.AppendLine('        <#')
                    $null = $result.AppendLine("            endregion End Parameter -${name} ####")
                    $null = $result.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                    $null = $result.AppendLine('        #>')
                    $null = $result.AppendLine()
                }
                # else, add to static parameters
                else {
                    $paramList.Add($parameter.Extent.Text)
                }
            }

            # determine the maximum parameter name length for formatting purposes:
            $longest = 0
            foreach ($_ in $dynParamList) {
                $longest = [Math]::Max($longest, $_.Length)
            }

            $null = $result.AppendLine(@'
        # return dynamic parameter collection:
        $paramDictionary
    }

    begin {
'@)

            $beginBlock = $FunctionInfo.ScriptBlock.Ast.Body.BeginBlock.extent.Text
            $beginBlockContent = $beginBlock -replace "^begin\s{\s?`n?" -replace '.*}$'
            if ($standardParamList.Count) {
                $null = $result.AppendLine('        <#')
                $null = $result.AppendLine('            region initialize variables for dynamic parameters')
                $null = $result.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                $null = $result.AppendLine('        #>')
                $null = $result.AppendLine()
                foreach ($varName in $dynParamList) {
                    $null = $result.AppendLine(('        if($PSBoundParameters.ContainsKey(''{0}'')) {{ ${0} = $PSBoundParameters[''{0}''] }}' -f $varName))
                    if ($defaultValues.ContainsKey($varName)) {
                        $null = $result.AppendLine(('        else {{ ${0} = {1} }}' -f $varName, $defaultValues[$varName]))
                    } else {
                        $null = $result.AppendLine(('        else {{ ${0} = $null}}' -f $varName))
                    }
                    $null = $result.AppendLine()
                }
                $null = $result.AppendLine('        <#')
                $null = $result.AppendLine('            endregion initialize variables for dynamic parameters')
                $null = $result.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                $null = $result.AppendLine('        #>')

                if (-not [string]::IsNullOrWhiteSpace($beginBlockContent)) {
                    $null = $result.AppendLine()
                }
            }

            if (-not [string]::IsNullOrWhiteSpace($beginBlockContent)) {
                $null = $result.AppendLine(@"
        $beginBlockContent
"@)
            }
            $null = $result.AppendLine(@"
    }

"@)

            $processBlock = $FunctionInfo.ScriptBlock.Ast.Body.ProcessBlock.extent.Text
            $processBlockContent = $processBlock -replace "^process\s{\s?`n?" -replace '.*}$'
            if (-not [string]::IsNullOrWhiteSpace($processBlock) -or $pipelineParamList.Count) {
                $null = $result.AppendLine('    process {')
                if ($pipelineParamList.Count) {
                    $null = $result.AppendLine('        <#')
                    $null = $result.AppendLine('            region update variables for pipeline-aware parameters:')
                    $null = $result.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                    $null = $result.AppendLine('        #>')
                    $null = $result.AppendLine()
                    foreach ($varName in $pipelineParamList) {
                        $null = $result.AppendLine(('        if ($PSBoundParameters.ContainsKey(''{0}'')) {{ ${0} = $PSBoundParameters[''{0}''] }}' -f $varName))
                        $null = $result.AppendLine()
                    }
                    $null = $result.AppendLine('        <#')
                    $null = $result.AppendLine('            endregion update variables for pipeline-aware parameters')
                    $null = $result.AppendLine('            created programmatically via Resolve-DynamicFunctionDefinition')
                    $null = $result.AppendLine('        #>')

                    if (-not [string]::IsNullOrWhiteSpace($processBlockContent)) {
                        $null = $result.AppendLine()
                    }
                }
                $null = $result.AppendLine("$processBlockContent    }")
            }

            $endBlock = $FunctionInfo.ScriptBlock.Ast.Body.EndBlock.extent
            $processBlockContent = $endBlock -replace '^end\s{\s?`n?' -replace '.*}$'
            if (-not [string]::IsNullOrWhiteSpace($endBlock)) {
                $null = $result.AppendLine($endBlock)
            }

            $null = $result.AppendLine('}')

            # insert list of static parameters (if any present)
            # into param() inside the composed code:
            # turn array of parameters in comma-separated list:
            $staticParams = $paramList -join ", `r`n`r`n        "
            # replace placeholder in the result with the static parameter list:
            $null = $result.Replace('##StaticParams##', $staticParams)

            # return composed script code, this will validate the compiled code
            return [ScriptBlock]::Create($result)
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}