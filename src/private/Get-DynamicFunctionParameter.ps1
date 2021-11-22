function Get-DynamicFunctionParameter {
    <#
        .SYNOPSIS
            Get the parameters from the provided array that have the [Dynamic()] attribute

        .DESCRIPTION
            Get-DynamicFunctionParameter filters the provided attributes and returns an
            array of parameters that have the [Dynamic()] attribute

        .EXAMPLE
            $parameterAst | Get-DynamicFunctionParameter

            Returns only the parameters that have the [Dynamic()] attribute

        .INPUTS
            System.Management.Automation.Language.ParameterAst

        .OUTPUTS
            System.Management.Automation.Language.ParameterAst[]
    #>

    [CmdletBinding()]
    param (
        # ParameterAst object(s)
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.Language.ParameterAst[]]$ParameterAst,

        # Type of parameter: static or dynamic
        [Parameter(Mandatory)]
        [ValidateSet(
            'static',
            'dynamic'
        )]
        [string]$Type
    )

    begin {
        try {
            switch ($Type) {
                'static'  { $typeDetector = 0 }
                'dynamic' { $typeDetector = 1 }
            }
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        try {
            $ParameterAst | ForEach-Object {
                $parameter = $_
                if ((Get-DynamicFunctionParameterDynamicAttribute -ParameterAst $parameter).Count -eq $typeDetector) {
                    return $parameter
                }
            }
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}