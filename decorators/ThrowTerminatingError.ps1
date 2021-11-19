function ThrowTerminatingErrorProxy {
    [CmdletBinding()]
    param (
        $Name,
        $CommandInfo
    )

    process {
        New-Item -Force -Path function: -Name $Name -Value {
            [CmdletBinding()]
            param(
                [Parameter(Position=0)]
                [System.Object]
                ${Name})
        
            begin
            {
                try {
                    $outBuffer = $null
                    if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                    {
                        $PSBoundParameters['OutBuffer'] = 1
                    }
        
                    # $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand("$Path", [System.Management.Automation.CommandTypes]::Function)
                    # $wrappedCmd = Get-Command $Using:Path
                    $scriptCmd = {& $CommandInfo @PSBoundParameters }
        
                    $steppablePipeline = $scriptCmd.GetSteppablePipeline($MyInvocation.CommandOrigin)
                    $steppablePipeline.Begin($PSCmdlet)
                } catch {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
        
            process
            {
                try {
                    $steppablePipeline.Process($_)
                } catch {
                    throw
                }
            }
        
            end
            {
                try {
                    $steppablePipeline.End()
                } catch {
                    throw
                }
            }
            <#
        
            .ForwardHelpTargetName Write-Hello
            .ForwardHelpCategory Function
        
            #>
        }.GetNewClosure()
    }

}