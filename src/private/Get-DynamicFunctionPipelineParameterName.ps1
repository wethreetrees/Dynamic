function Get-DynamicFunctionPipelineParameterName {
    <#
        .SYNOPSIS
            Gets the names of any pipeline bound parameters

        .DESCRIPTION
            Get-DynamicFunctionPipelineParameterName gets the names of any pipeline
            bound parameters defined in the provided ParameterAst object(s)

        .EXAMPLE
            Get-DynamicFunctionPipelineParameterName -ParameterAst $parameterAst

            Gets the names of any pipeline bound parameters

        .INPUTS
            System.Management.Automation.Language.ParameterAst

        .OUTPUTS
            string
            string[]
    #>

    [CmdletBinding()]
    param (
        # ParameterAst objects to evaluate for pipeline binding
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.Language.ParameterAst[]]$ParameterAst
    )

    begin {
        $pipelineAttribs = @(
            'ValueFromPipeline',
            'ValueFromPipelineByPropertyName'
        )
    }

    process {
        try {
            $ParameterAst | ForEach-Object {
                $parameter = $_

                $parameter.Attributes | ForEach-Object {
                    $attribute = $_

                    if ($attribute -is [System.Management.Automation.Language.AttributeAst]) {
                        $attribute.NamedArguments | ForEach-Object {
                            $namedArgument = $_
                            if ($namedArgument.ArgumentName -in $pipelineAttribs) {
                                return $parameter.Name.VariablePath.UserPath
                            }
                        }
                    }
                }
            }
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}