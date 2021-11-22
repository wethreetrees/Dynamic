BeforeDiscovery {
    # Setup parameter test cases
    $parameterTestCases = @(
        @{
            Name      = 'Definition'
            Mandatory = $true
            Type      = [string]
        }
    )
}

Describe "Test-DynamicFunctionDefinition Unit Tests" -Tag Unit {

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
            $commandInfo = InModuleScope -ModuleName Dynamic -ScriptBlock { Get-Command -Name 'Test-DynamicFunctionDefinition' }
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

}

Describe "Test-DynamicFunctionDefinition Integration Tests" -Tag Integration {

    BeforeAll {
        Remove-Module -Name Dynamic -Force -ErrorAction SilentlyContinue
        Import-Module $PSScriptRoot/../../dist/Dynamic -Force
    }

    Context "Valid function definition" {

        It "Should fail" {
            InModuleScope -ModuleName Dynamic -ScriptBlock {
                { Test-DynamicFunctionDefinition -Definition "function {" } | Should -Throw "Function definition is invalid: *"
            }
        }

    }

    Context "Invalid function definition" {

        It "Should succeed and return scriptblock" {
            InModuleScope -ModuleName Dynamic -ScriptBlock {
                $testScriptBlock = { Test-DynamicFunctionDefinition -Definition "function hello { 'hello' }" }
                $testScriptBlock | Should -Not -Throw
                $result = . $testScriptBlock
                $result | Should -BeExactly "function hello { 'hello' }"
            }
        }

    }

}

