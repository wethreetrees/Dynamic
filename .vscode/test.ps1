# test.ps1
[CmdletBinding()]
param (
    [String] $Path = ".",
    [String] $Output = "Normal",
    [Switch] $CodeCoverage
)

$Configuration = New-PesterConfiguration

$Configuration.Run.Path = $Path

$Configuration.Output.Verbosity = $Output

$Configuration.CodeCoverage.Enabled = [bool] $CodeCoverage
# CoverageGutters is new option in Pester 5.2 pre-release
$Configuration.CodeCoverage.OutputFormat = "CoverageGutters"
$Configuration.CodeCoverage.Path = "$PSScriptRoot/../src"
$Configuration.CodeCoverage.OutputPath = "$PSScriptRoot/../build/gutters.xml"
$Configuration.CodeCoverage.CoveragePercentTarget = 90

$Configuration.Debug.WriteDebugMessages = $true
$Configuration.Debug.WriteDebugMessagesFrom = "CodeCoverage"


# for convenience just run the passed file when we invoke this via launchConfig.json when
# the file is a non-test file
$isDirectory = (Get-Item $Path).PSIsContainer
$isTestFile = $Path.EndsWith($Configuration.Run.TestExtension.Value)
if (-not $isDirectory -and -not $isTestFile) {
    & $Path
    return
}

Invoke-Pester -Configuration $Configuration
