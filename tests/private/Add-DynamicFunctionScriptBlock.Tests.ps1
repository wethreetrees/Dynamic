BeforeDiscovery {
    # Setup parameter test cases
    $parameterTestCases = @(
        @{
            Name      = 'StringBuilder'
            Mandatory = $true
            Type      = [System.Text.StringBuilder]
        },
        @{
            Name      = 'Name'
            Mandatory = $true
            Type      = [string]
        },
        @{
            Name      = 'Content'
            Mandatory = $false
            Type      = [string]
        },
        @{
            Name      = 'Parameter'
            Mandatory = $false
            Type      = [string[]]
        },
        @{
            Name      = 'DefaultValueTable'
            Mandatory = $false
            Type      = [hashtable]
        }
    )

    # Setup custom function test cases
}

Describe "Add-DynamicFunctionScriptBlock Unit Tests" -Tag Unit {

    BeforeAll {
        $moduleProjectPath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $moduleName        = (Get-Item $moduleProjectPath).BaseName
        # Remove all versions of the module from the session. Pester can't handle multiple versions.
        Get-Module $ModuleName | Remove-Module -Force
        Import-Module $moduleProjectPath\dist\$ModuleName -ErrorAction Stop -Force
    }

    Context "Parameter Tests" {

        BeforeAll {
            # Executing this in the module scope since private functions are not available
            $commandInfo = InModuleScope -ModuleName Dynamic -ScriptBlock { Get-Command -Name 'Add-DynamicFunctionScriptBlock' }
        }

        It 'Should have [<Type>] parameter [<Name>] ' -TestCases $parameterTestCases {
            $commandInfo | Should -HaveParameter $Name -Type $Type
            if ($Mandatory) {
                $commandInfo | Should -HaveParameter $Name -Mandatory
            } else {
                $commandInfo | Should -HaveParameter $Name -Not -Mandatory
            }
        }

    }

    # Context "Use case" {

    #     BeforeAll {

    #     }

    #     It "Should have some result" {
    #         Assertion
    #     }

    # }
    # ...

}

Describe "Add-DynamicFunctionScriptBlock Integration Tests" -Tag Integration {

    # Context "Use case" {

    #     BeforeAll {

    #     }

    #     It "Should have some result" {
    #         Assertion
    #     }

    # }
    # ...

}

