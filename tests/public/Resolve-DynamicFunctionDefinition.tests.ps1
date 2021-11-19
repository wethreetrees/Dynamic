Describe "Resolve-DynamicFunctionDefinition Integration Tests" -Tags Integration {

    Context "Import Test Module" {

        It "Should successfully import test module" {
            { Import-Module $PSScriptRoot/../resources/WriteHello -Force } | Should -Not -Throw
        }

    }

    Context "Rewrite function definitions in a module" {

        BeforeAll {
            Import-Module $PSScriptRoot/../resources/WriteHello -Force
        }

        It "Should not allow dynamic parameter when condition is wrong" {
            { Write-Hello -Name Tyler -Planet Earth } | Should -Throw "A parameter cannot be found that matches parameter name 'Planet'."
        }

        It "Should allow dynamic parameter when condition is correct" {
            Write-Hello -Planet Earth | Should -BeExactly @("Hello, World!", "Welome to Earth!")
        }

        It "Should return correct value under normal conditions" {
            Write-Hello -Name Tyler | Should -BeExactly "Hello, Tyler!"
        }

        AfterAll {
            Remove-Module WriteHello -Force
        }

    }

    Context "Correctly redefine function with dynamic parameters" {

        BeforeAll {
            Remove-Module Dynamic -Force -ErrorAction SilentlyContinue
            Import-Module $PSScriptRoot/../../dist/Dynamic -Force

            . "$PSScriptRoot/../resources/WriteHello/public/Write-Hello.ps1"
            $functionInfo = Get-Command -Name Write-Hello
        }

        It "Should successfully redefine the function" {
            { Resolve-DynamicFunctionDefinition -FunctionInfo $functionInfo } | Should -Not -Throw
        }

        It "Should return expected function definition. with dynamic parameters" {
            if ($env:OS -like 'Windows*') {
                # TODO: Look at solutions to allow string matching from file to work in Linux

                $expected = Get-Content -Path "$PSScriptRoot/../resources/FunctionDefinitions/Write-Hello.dyndef.ps1" -Raw
                [string]$dyndef = Resolve-DynamicFunctionDefinition -FunctionInfo $functionInfo

                $dyndef | Should -BeExactly $expected
            } else {
                Set-ItResult -Skipped -Because "Linux comparison fails on line endings"
            }
        }

        AfterAll {
            Remove-Module Dynamic -Force
        }

    }

}