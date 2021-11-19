#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.2.2'; MaximumVersion = '5.*' }

Import-Module Pester -MinimumVersion 5.2.2 -MaximumVersion 5.*

function Should-BeObject($ActualValue, $ExpectedObject, [switch] $Negate, [string] $Because) {
    <#
    .SYNOPSIS
        Asserts that each property value of the provided object
        matches the expected object exactly.
    .EXAMPLE
        @{name = 'test'; value = @{num = 12345}} | Should -BeObject @{name = 'test'; value = @{num = 12345}}

        Checks if all object properties are the same. This should pass.
    .EXAMPLE
        @{name = 'test'; value = @{num = 54321}} | Should -BeObject @{name = 'test'; value = @{num = 12345}}

        Checks if all object properties are the same. This should not pass.
    #>

    $results = Compare-PSObject -ReferenceObject $ExpectedObject -DifferenceObject $ActualValue
    [bool] $succeeded = -not ('NotEqual' -in $results.Indicator)
    if ($Negate) { $succeeded = -not $succeeded }

    if (-not $succeeded) {
        if ($Negate) {
            $failureMessage = (
                "Objects should be the different, but they were the same: `n`n" +
                "$($results | Out-String)"
            )
        } else {
            $failureMessage = (
                "Objects should be the same, but differences were found: `n`n" +
                "$($results | Out-String)"
            )
        }
    }

    return New-Object psobject -Property @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

Add-ShouldOperator -Name BeObject -Test ${function:Should-BeObject} -InternalName 'Should-BeObject' -SupportsArrayInput