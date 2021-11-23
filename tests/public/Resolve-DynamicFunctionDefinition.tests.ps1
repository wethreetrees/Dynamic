BeforeDiscovery {
    # Setup parameter test cases
    $parameterTestCases = @(
        @{
            Name      = 'FunctionInfo'
            Mandatory = $true
            Type      = [System.Management.Automation.FunctionInfo]
        },
        @{
            Name      = 'Force'
            Mandatory = $false
            Type      = [switch]
        }
    )

    # Setup custom function test cases
    $TestModulePath = "$PSScriptRoot/../resources/TestModules/WriteHello"
    $expectedFileDir = Join-Path -Path (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath resources) -ChildPath FunctionDefinitions
    $functionTestCases = Get-ChildItem -Path (Join-Path -Path $TestModulePath -ChildPath public) |
        ForEach-Object {
            $expectedFilePath = Join-Path -Path $expectedFileDir -ChildPath ($_.Name -replace '.ps1', '.dyndef.ps1')
            @{
                FunctionName = $_.BaseName
                FunctionFile = $_.FullName
                ExpectedFile = $expectedFilePath
            }
        }
}

Describe "Resolve-DynamicFunctionDefinition Unit Tests" -Tag Unit {

    BeforeAll {
        $moduleProjectPath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $moduleName        = (Get-Item $moduleProjectPath).BaseName
        # Remove all versions of the module from the session. Pester can't handle multiple versions.
        Get-Module $ModuleName | Remove-Module -Force
        Import-Module $moduleProjectPath\dist\$ModuleName -ErrorAction Stop -Force
    }

    Context "Parameter Tests" {

        BeforeAll {
            $commandInfo = Get-Command -Name 'Resolve-DynamicFunctionDefinition'
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

Describe "Resolve-DynamicFunctionDefinition Integration Tests" -Tag Integration {

    BeforeAll {
        Remove-Module -Name Dynamic -Force -ErrorAction SilentlyContinue
        Import-Module $PSScriptRoot/../../dist/Dynamic -Force

        $TestModulePath = "$PSScriptRoot/../resources/TestModules/WriteHello"
    }

    Context "Import Test Module" {

        It "Should successfully import test module" {
            { Import-Module $TestModulePath -Force } | Should -Not -Throw
        }

    }

    Context "Rewrite function definitions in a module" {

        BeforeAll {
            Import-Module $TestModulePath -Force
        }

        It "Should not allow dynamic parameter when condition is wrong" {
            { Write-Hello -Name Tyler -Planet Earth } | Should -Throw "A parameter cannot be found that matches parameter name 'Planet'."
        }

        It "Should allow dynamic parameter when condition is correct" {
            Write-Hello -Planet Earth | Should -BeExactly @("Hello, World!", "Welcome to Earth!")
        }

        It "Should return correct value under normal conditions" {
            Write-Hello -Name Tyler | Should -BeExactly "Hello, Tyler!"
        }

        AfterAll {
            Remove-Module WriteHello -Force
        }

    }

    Context "Correctly redefine function with dynamic parameters: [<FunctionName>]" -Foreach $functionTestCases {

        BeforeAll {
            . $FunctionFile
            $functionInfo = Get-Command -Name $FunctionName
        }

        It "Should successfully redefine the function" {
            { Resolve-DynamicFunctionDefinition -FunctionInfo $functionInfo -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It "Should return expected function definition. with dynamic parameters" {
            if ($env:OS -like 'Windows*') {
                # TODO: Look at solutions to allow string matching from file to work in Linux

                $expected = Get-Content -Path $ExpectedFile -Raw -ErrorAction Stop
                [string]$dyndef = Resolve-DynamicFunctionDefinition -FunctionInfo $functionInfo -WarningAction SilentlyContinue

                $dyndef | Should -BeExactly $expected
            } else {
                Set-ItResult -Skipped -Because "Linux comparison fails on line endings"
            }
        }

    }

    Context "Correctly redefine simple function, with -Force" {

        It "Should return expected function definition, with dynamic parameters" {
            if ($env:OS -like 'Windows*') {
                # TODO: Look at solutions to allow string matching from file to work in Linux

                . "$PSScriptRoot/../resources/TestFunctions/Write-HiForce.ps1"

                $functionInfo = Get-Command -Name Write-HiForce

                $expected = Get-Content -Path "$PSScriptRoot/../resources/FunctionDefinitions/Write-HiForce.dyndef.ps1" -Raw -ErrorAction Stop
                [string]$dyndef = Resolve-DynamicFunctionDefinition -FunctionInfo $functionInfo -Force

                $dyndef | Should -BeExactly $expected
            } else {
                Set-ItResult -Skipped -Because "Linux comparison fails on line endings"
            }
        }

    }

}

