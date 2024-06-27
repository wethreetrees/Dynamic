[CmdletBinding(DefaultParameterSetName = 'Default')]
Param (
    [Parameter(Position = 0)]
    $Task = 'Default',

    [Parameter(Mandatory, ParameterSetName = 'Coverage')]
    [switch]$Coverage,

    [Parameter()]
    [switch]$CI,

    [Parameter(ParameterSetName = 'Coverage')]
    [double]$MinimumCoverage = 70,

    [Parameter()]
    [switch]$Help
)

DynamicParam {
    # Adapted from https://github.com/nightroman/Invoke-Build/blob/master/Invoke-Build.ArgumentCompleters.ps1

    Register-ArgumentCompleter -CommandName build.ps1 -ParameterName Task -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

        $tasks = (Invoke-Build -Task ?? -File "$PSScriptRoot\build_tools\module.build.ps1").get_Keys()

        $tasks -like "$wordToComplete*" | . {
            process {
                New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
            }
        }
    }
}

process {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $ModuleName = (Get-Item -Path $PSScriptRoot).BaseName

    # Writing out the current script parameters for troubleshooting logs
    $params = @{}
    foreach($h in $MyInvocation.MyCommand.Parameters.GetEnumerator()) {
        if (
            ($PSCmdlet.ParameterSetName -in $h.Value.ParameterSets.Keys) -or
            ('__AllParameterSets' -in $h.Value.ParameterSets.Keys)
        ) {
            try {
                $key = $h.Key
                $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
                if (([String]::IsNullOrEmpty($val) -and (-not $PSBoundParameters.ContainsKey($key)))) {
                    throw "A blank value that wasn't supplied by the user."
                }
                $params[$key] = $val
            } catch {}
        }
    }
    if ($params.Keys) {
        Write-Output "Build Parameters:`n$($params | Out-String)"
    }

    $buildFile = "$PSScriptRoot\build_tools\module.build.ps1"
    $buildDependencies = Import-PowerShellDataFile -Path $PSScriptRoot\build_tools\build.Depend.psd1
    $PSDependVersion = $buildDependencies.PSDepend
    $InvokeBuildVersion = $buildDependencies.InvokeBuild.Version

    Write-Output 'Installing/Importing Build-Dependent Modules'
    if (-not (Get-Module -Name 'PSDepend' -ListAvailable | Where-Object { $PSDependVersion -in $_.Version })) {
        Write-Output '  PSDepend module required: Installing...'
        Install-Module -Name 'PSDepend' -Repository PSGallery -RequiredVersion $PSDependVersion -Force -Scope 'CurrentUser'
    }
    Import-Module -Name 'PSDepend' -RequiredVersion $PSDependVersion

    if (-not (Get-Module -Name 'InvokeBuild' -ListAvailable | Where-Object { $InvokeBuildVersion -in $_.Version })) {
        Write-Output '  InvokeBuild module required: Installing...'
        Install-Module -Name 'InvokeBuild' -Repository PSGallery -RequiredVersion $InvokeBuildVersion -Force -Scope 'CurrentUser'
    }
    Import-Module -Name 'InvokeBuild' -RequiredVersion $InvokeBuildVersion

    if ($Help) {
        Invoke-Build -File $buildFile -Task ?
    } else {
        $invokePSDependParams = @{
            Path          = "$PSScriptRoot\build_tools\build.Depend.psd1"
            Tags          = 'Build'
            Install       = $true
            Import        = $true
            Force         = $true
            WarningAction = 'SilentlyContinue'
            Verbose       = $VerbosePreference
        }
        Invoke-PSDepend @invokePSDependParams

        if (-not (Get-PackageProvider -Name 'NuGet')) {
            Write-Output '  Installing Nuget package provider...'
            Install-PackageProvider -Name 'NuGet' -Force -Confirm:$false | Out-Null
        }

        Write-Output "Starting build of $ModuleName"
        $InvokeBuildParams = @{
            File             = $buildFile
            Task             = $Task
            ModuleName       = $ModuleName
            Coverage         = $Coverage
            MinimumCoverage  = $MinimumCoverage
            Verbose          = $VerbosePreference
        }
        Invoke-Build @InvokeBuildParams
    }
}

