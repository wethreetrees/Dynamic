BeforeDiscovery {
    # Setup parameter test cases
    $parameterTestCases = @(
        @{
            Name      = 'StringBuilder'
            Mandatory = $true
            Type      = [System.Text.StringBuilder]
        },
        @{
            Name      = 'ParameterAst'
            Mandatory = $true
            Type      = [System.Management.Automation.Language.ParameterAst[]]
        },
        @{
            Name      = 'DefaultValueTable'
            Mandatory = $false
            Type      = [hashtable]
        }
    )

}

BeforeAll {
    $moduleProjectPath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    $moduleName        = (Get-Item $moduleProjectPath).BaseName
    # Remove all versions of the module from the session. Pester can't handle multiple versions.
    Get-Module $ModuleName | Remove-Module -Force
    Import-Module $moduleProjectPath\dist\$ModuleName -ErrorAction Stop -Force
}

Describe "Add-DynamicFunctionDynamicParamBlock Unit Tests" -Tag Unit {

    Context "Parameter Tests" {

        BeforeAll {
            # Executing this in the module scope since private functions are not available
            $commandInfo = InModuleScope -ModuleName Dynamic -ScriptBlock { Get-Command -Name 'Add-DynamicFunctionDynamicParamBlock' }
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

Describe "Add-DynamicFunctionDynamicParamBlock Integration Tests" -Tag Integration {

    BeforeAll {
        $newLineChar = [System.Environment]::NewLine
        $requiredContent = @(
            '*$paramDictionary = `[System.Management.Automation.RuntimeDefinedParameterDictionary`]::new()*',
            '*$attributeCollection = `[System.Collections.ObjectModel.Collection`[System.Attribute`]`]::new()*'
            '*$paramDictionary*'
        )
    }

    Context "Add a single dynamic parameter definition" {

        BeforeAll {
            $TestFunctionPath = "$PSScriptRoot/../resources/TestModules/WriteHello/public/Write-Hello.ps1"
            . $TestFunctionPath

            $functionInfo = Get-Command -Name Write-Hello

            $parameters = $functionInfo.ScriptBlock.ast.Body.ParamBlock[0].Parameters | Where-Object {
                'Dynamic' -in $_.Attributes.typename.name
            }

            $stringBuilder = New-Object -TypeName System.Text.StringBuilder

            $parameterContent = @(
                '*$null -eq $PSBoundParameters`[''Name''`]*',
                '*$attributeCollection = `[System.Collections.ObjectModel.Collection`[System.Attribute`]`]::new()*'
                '*$attrib = `[Parameter`]::new()*'
                '*$attrib.Mandatory = $true*'
                '*$attributeCollection.Add($attrib)*'
                '*$attrib = `[ValidateSet`]::new(''Mercury'', ''Venus'', ''Earth'', ''Mars'', ''Jupiter'', ''Saturn'', ''Uranus'', ''Neptune'')*'
                '*$attributeCollection.Add($attrib)*'
                '*$dynParam = `[System.Management.Automation.RuntimeDefinedParameter`]::new(''Planet'', `[string`], $attributeCollection)*'
                '*$paramDictionary.Add(''Planet'', $dynParam)*'
            )
        }

        It "Should have some result" {
            InModuleScope -ModuleName $ModuleName -ScriptBlock {
                $parameters | Add-DynamicFunctionDynamicParamBlock -StringBuilder $stringBuilder
            } -Parameters @{ parameters = $parameters; stringBuilder = $stringBuilder }

            foreach ($line in $requiredContent + $parameterContent) {
                $stringBuilder.ToString() | Should -BeLike $line
            }
        }

        It "Should be valid code" {
            { [scriptblock]::Create($stringBuilder.ToString()) } | Should -Not -Throw
        }

    }

    Context "Add multiple dynamic parameter definitions" {

        BeforeAll {
            $TestFunctionPath = "$PSScriptRoot/../resources/TestFunctions/Send-FoodOrder.ps1"
            . $TestFunctionPath

            $functionInfo = Get-Command -Name Send-FoodOrder

            $parameters = $functionInfo.ScriptBlock.ast.Body.ParamBlock[0].Parameters | Where-Object {
                'Dynamic' -in $_.Attributes.typename.name
            }

            $stringBuilder = New-Object -TypeName System.Text.StringBuilder
        }

        It "Should have some result" {
            InModuleScope -ModuleName $ModuleName -ScriptBlock {
                $parameters | Add-DynamicFunctionDynamicParamBlock -StringBuilder $stringBuilder
            } -Parameters @{ parameters = $parameters; stringBuilder = $stringBuilder }

            foreach ($line in $requiredContent) {
                $stringBuilder.ToString() | Should -BeLike $line
            }
        }

        It "Should be valid code" {
            { [scriptblock]::Create($stringBuilder.ToString()) } | Should -Not -Throw
        }

    }

}

