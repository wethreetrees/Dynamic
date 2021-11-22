BeforeDiscovery {
    # Setup parameter test cases
    $parameterTestCases = @(
        @{
            Name      = 'StringBuilder'
            Mandatory = $true
            Type      = [System.Text.StringBuilder]
        },
        @{
            Name      = 'ParamBlockAst'
            Mandatory = $true
            Type      = [System.Management.Automation.Language.ParamBlockAst]
        }
    )

    # Setup custom function test cases
}

Describe "Add-DynamicFunctionAttribute Unit Tests" -Tag Unit {

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
            $commandInfo = InModuleScope -ModuleName Dynamic -ScriptBlock { Get-Command -Name 'Add-DynamicFunctionAttribute' }
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

    Context "Add a single function attribute to the stringbuilder, without modifying the original content" {

        BeforeAll {
            $newLineChar = [Environment]::NewLine
            $stringBuilder = New-Object -Type System.Text.StringBuilder
            $stringBuilder.AppendLine('ORIGINAL_CONTENT')
            $mockParamBlockAst = New-MockObject -Type System.Management.Automation.Language.ParamBlockAst -Properties @{
                Attributes = @(
                    @{ Extent = @{ Text = "[CmdletBinding()]" } }
                )
            }
        }

        It "Should add [CmdletBinding()] attribute to stringbuilder" {
            InModuleScope -ModuleName $moduleName -ScriptBlock {
                Add-DynamicFunctionAttribute -StringBuilder $sb -ParamBlockAst $pbAst
            } -Parameters @{ sb = $stringBuilder; pbAst = $mockParamBlockAst }

            $stringBuilder.ToString() | Should -Be "ORIGINAL_CONTENT$newLineChar    [CmdletBinding()]$newLineChar"
        }

    }

}

Describe "Add-DynamicFunctionAttribute Integration Tests" -Tag Integration {

    # Context "Use case" {

    #     BeforeAll {

    #     }

    #     It "Should have some result" {
    #         Assertion
    #     }

    # }
    # ...

}

