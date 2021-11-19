Describe "Set-DynamicParameterDefinition Integration Tests" -Tags Integration {

    Context "Rewrite function definitions in a module" {

        It "Should successfully import test module" {
            { Import-Module $PSScriptRoot/resources/WriteHello -Force } | Should -Not -Throw
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
            Remove-Module PSDynParam -Force -ErrorAction SilentlyContinue
            Import-Module $PSScriptRoot/../PSDynParam.psd1 -Force

            . "$PSScriptRoot/resources/WriteHello/public/Write-Hello.ps1"
            $functionInfo = Get-Command -Name Write-Hello
        }

        It "Should successfully redefine the function" {
            { Set-DynamicParameterDefinition -FunctionInfo $functionInfo } | Should -Not -Throw
        }

        It "Should return expected function definition. with dynamic parameters" {
            $expected = Get-Content -Path "$PSScriptRoot/resources/FunctionDefinitions/Write-Hello.dyndef.ps1" -Raw
            [string]$dyndef = Set-DynamicParameterDefinition -FunctionInfo $functionInfo
            $dyndef | Should -BeExactly $expected
        }

        AfterAll {
            Remove-Module PSDynParam -Force
        }

    }

}