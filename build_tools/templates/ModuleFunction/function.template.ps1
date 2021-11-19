<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <%= $PLASTER_PARAM_FunctionName %>
    Explanation of what the example does
.PARAMETER Parameter
    This is a description for the parameter
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
#>

function <%= $PLASTER_PARAM_FunctionName %> {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object]$Parameter
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        try {

        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

}
