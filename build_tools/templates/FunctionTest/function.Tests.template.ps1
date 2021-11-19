BeforeDiscovery {
    # Setup parameter test cases
    $paramTestCases = @(
        # @{
        #     Name      = 'ParameterName'
        #     Mandatory = $true
        #     Type      = [string]
        # },
        # ...
    )

    # Setup custom function test cases
}

Describe "<%= $PLASTER_PARAM_FunctionName %> Unit Tests" -Tag Unit {

    BeforeAll {
        $moduleProjectPath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
        $moduleName        = (Get-Item $moduleProjectPath).BaseName
        # Remove all versions of the module from the session. Pester can't handle multiple versions.
        Get-Module $ModuleName | Remove-Module -Force
        Import-Module $moduleProjectPath\dist\$ModuleName -ErrorAction Stop -Force
    }

    Context "Parameter Tests" {

        BeforeAll {
<%
                if ($PLASTER_PARAM_FunctionType -eq 'Private') {
            @'
            # Executing this in the module scope since private functions are not available
            $commandInfo = InModuleScope -ModuleName <%= $PLASTER_PARAM_ModuleName %> -ScriptBlock { Get-Command -Name '<%= $PLASTER_PARAM_FunctionName %>' }
'@
                } else {
            @'
            $commandInfo = Get-Command -Name '<%= $PLASTER_PARAM_FunctionName %>'
'@
                }
%>
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

Describe "<%= $PLASTER_PARAM_FunctionName %> Integration Tests" -Tag Integration {

    # Context "Use case" {

    #     BeforeAll {

    #     }

    #     It "Should have some result" {
    #         Assertion
    #     }

    # }
    # ...

}
