class DynamicParameter {
    DynamicParameter ([scriptblock]$Definition) {

    }
}

$param = {
    param(
        [Parameter(Mandatory)]
        [Alias('testing')]
        [string]$test
    )
}

$tempfunc = New-Item -Path function: -Name tempfunc -Value $param -Force

$commonParams = @(
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

$dynParams = $tempfunc.Parameters.GetEnumerator() | ForEach-Object { if ($_.Key -notin $commonParams) { $_.Value } }

$paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

foreach ($dynParam in $dynParams) {
    # Defining the runtime parameter
    $runtimeDynParam = New-Object -Type System.Management.Automation.RuntimeDefinedParameter($dynParam.Name, $dynParam.ParameterType, $dynParam.Attributes)
    $paramDictionary.Add($dynParam.Name, $runtimeDynParam)
}

return $paramDictionary