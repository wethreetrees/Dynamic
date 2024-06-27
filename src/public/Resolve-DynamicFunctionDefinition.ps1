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

        .INPUTS
            System.Management.Automation.FunctionInfo

        .OUTPUTS
            scriptblock

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
        # FunctionInfo object for the function to evaluate and process for parameters with the [Dynamic()] attribute
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.FunctionInfo]$FunctionInfo,

        # Forces functions missing the [CmdletBinding()] attribute, to be interpreted as advanced functions
        [Parameter()]
        [switch]$Force
    )

    process {
        try {
            # This is the object that we will use to build up the new function definition
            $result = New-Object -TypeName System.Text.StringBuilder

            # Store dynamic parameter default values
            $defaultValues = @{}

            # Store list of dynamic parameters
            $dynParamList = [System.Collections.ObjectModel.Collection[string]]::new()

            # Store list of static parameters
            $paramList = [System.Collections.ObjectModel.Collection[string]]::new()

            # Store list of non-pipeline bound parameters
            $standardParamList = [System.Collections.ObjectModel.Collection[string]]::new()

            $commentBasedHelpString = Get-DynamicFunctionCommentBasedHelp -FunctionInfo $FunctionInfo
            if ($commentBasedHelpString) {
                $null = $result.AppendLine($commentBasedHelpString)
            }

            # If function does not contain cmdlet binding, return the original definition
            if (Assert-DynamicFunctionIsAdvanced -FunctionInfo $FunctionInfo) {
                $null = $result.AppendLine("function $($FunctionInfo.Name) {")
            } else {
                if (-not $Force) {
                    Write-Warning "$($FunctionInfo.Name) is not an advanced function, using original function content"
                    return Resolve-DynamicSimpleFunction -FunctionInfo $FunctionInfo
                } else {
                    $null = $result.AppendLine("function $($FunctionInfo.Name) {")
                    $null = $result.AppendLine("    [CmdletBinding()]")
                }
            }

            $paramBlockAst = Get-DynamicFunctionParamBlockContent -FunctionInfo $FunctionInfo

            Add-DynamicFunctionAttribute -StringBuilder $result -ParamBlockAst $paramBlockAst

            # Add a placeholder that will be replaced after processing for [Dynamic()] tagged parameters
            Add-DynamicFunctionParamBlockPlaceholder -StringBuilder $result

            $dynamicParameters = $paramBlockAst.Parameters | Get-DynamicFunctionParameter -Type 'dynamic'
            $staticParameters = $paramBlockAst.Parameters | Get-DynamicFunctionParameter -Type 'static'

            if ($dynamicParameters) {
                $dynamicParameters | Add-DynamicFunctionDynamicParamBlock -StringBuilder $result -DefaultValueTable $defaultValues
                foreach ($dynamicParameter in $dynamicParameters) {
                    $parameterName = $dynamicParameter.Name.VariablePath.UserPath
                    $dynParamList.Add($parameterName)
                }
                $pipelineParamList = $dynamicParameters | Get-DynamicFunctionPipelineParameterName
            }

            if ($staticParameters) {
                foreach ($staticParameter in $staticParameters) {
                    $staticParameterCommentHelp = Get-DynamicFunctionParameterCommentHelp -ParameterAst $staticParameter -FunctionInfo $FunctionInfo

                    $staticParamStringBuilder = New-Object -TypeName System.Text.StringBuilder

                    if ($staticParameterCommentHelp) {
                        $null = $staticParamStringBuilder.AppendLine($staticParameterCommentHelp)
                        $null = $staticParamStringBuilder.Append("        " + $staticParameter.Extent.Text)
                    } else {
                        $null = $staticParamStringBuilder.Append($staticParameter.Extent.Text)
                    }


                    $paramList.Add($staticParamStringBuilder.ToString())
                }
            }

            $dynParamList | ForEach-Object {
                $dynParam = $_
                if ($dynParam -notin $pipelineParamList) {
                    $null = $standardParamList.Add($dynParam)
                }
            }

            $beginBlockContent = Get-DynamicFunctionScriptBlockContent -Name begin -FunctionInfo $FunctionInfo
            $needsBeginBlock = $dynParamList.Count -or -not [string]::IsNullOrWhiteSpace($beginBlockContent)
            if ($needsBeginBlock) {
                Add-DynamicFunctionScriptBlock -StringBuilder $result -Name begin -Content $beginBlockContent -Parameter $dynParamList -DefaultValueTable $defaultValues
            }

            $processBlockContent = Get-DynamicFunctionScriptBlockContent -Name process -FunctionInfo $FunctionInfo
            $needsProcessBlock = -not [string]::IsNullOrWhiteSpace($processBlockContent) -or $pipelineParamList.Count
            if ($needsProcessBlock) {
                Add-DynamicFunctionScriptBlock -StringBuilder $result -Name process -Content $processBlockContent -Parameter $pipelineParamList
            }

            $endBlockContent = Get-DynamicFunctionScriptBlockContent -Name end -FunctionInfo $FunctionInfo
            if (-not [string]::IsNullOrWhiteSpace($endBlockContent)) {
                Add-DynamicFunctionScriptBlock -StringBuilder $result -Name end -Content $endBlockContent
            }

            # Add the function block's closing brace
            $null = $result.Append('}')

            Set-DynamicFunctionParamBlockPlaceholder -StringBuilder $result -ParameterList $paramList

            Test-DynamicFunctionDefinition -Definition $result
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
