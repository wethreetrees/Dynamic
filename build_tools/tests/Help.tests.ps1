# Adapted from @juneb_get_help (https://raw.githubusercontent.com/juneb/PesterTDD/master/Module.Help.Tests.ps1)

BeforeDiscovery {
    ## When testing help, remember that help is cached at the beginning of each session.
    ## To test, restart session.

    $moduleProjectPath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    $moduleName        = (Get-Item $moduleProjectPath).BaseName
    # Remove all versions of the module from the session. Pester can't handle multiple versions.
    Get-Module $ModuleName | Remove-Module -Force
    Import-Module $moduleProjectPath\dist\$ModuleName -ErrorAction Stop -Force

    # Setting up test cases
    $commands = Get-Command -Module $ModuleName -CommandType Cmdlet, Function, Script  # Not alias
    $helpHash = @{}
    $documentationTestCases = $commands | ForEach-Object {
        $commandName = $_.Name
        # The module-qualified command fails on Microsoft.PowerShell.Archive cmdlets
        $helpHash["$commandName"] = Get-Help $commandName -Full -ErrorAction SilentlyContinue
        @{ CommandName = $commandName; Help = $helpHash[$commandName] }
    }

    $commonParameters = @(
        'Debug',
        'ErrorAction',
        'ErrorVariable',
        'InformationAction',
        'InformationVariable',
        'OutBuffer',
        'OutVariable',
        'PipelineVariable',
        'Verbose',
        'WarningAction',
        'WarningVariable',
        'Confirm',
        'Whatif',
        'ProgressAction'
    )

    $commandParametersTestCases = $commands | ForEach-Object {
        $commandName = $_.Name

        try {
            $parameters = $_.ParameterSets.Parameters |
                Sort-Object -Property IsMandatory |
                Sort-Object -Property Name -Unique |
                Where-Object { $_.Name -notin $commonParameters }

            $parameters | ForEach-Object {
                $parameterName = $_.Name
                @{
                    CommandName   = $commandName
                    ParameterName = $parameterName
                    ParameterHelp = $helpHash[$commandName].parameters.parameter | Where-Object { $_.Name -eq $parameterName }
                    Parameter     = $_
                }
            }
        } catch {
            Write-Warning "Could not parse parameters for command [$commandName]"
        }
    }

    $linksTestCases = $commands | ForEach-Object {
        $commandName = $_.Name

        try {
            $commandLinks = $helpHash[$commandName].relatedLinks.navigationLink

            if ($commandLinks) {
                $commandLinks | ForEach-Object {
                    $commandLink = $_
                    if ($commandLink.uri) {
                        $link = $commandLink.uri
                    } else {
                        $link = $commandLink.linkText
                    }
                    @{ CommandName = $commandName; Link = $link }
                }
            }
        } catch {
            Write-Warning "Could not parse links for command [$commandName]"
        }
    }
}

Describe 'Test Help' {

    Context 'Help Documentation for [<CommandName>]' -ForEach $documentationTestCases {
        # If help is not found, synopsis in auto-generated help is the syntax diagram
        It 'Should not be auto-generated' {
            $help.Synopsis | Should -Not -BeLike '*`[`<CommonParameters`>`]*'
        }

        # Should not have the default code snippet Synopsis
        It 'Should not have default Synopsis' {
            $help.Synopsis | Should -Not -Be 'Short description'
        }

        # Should not have the default code snippet Description
        It 'Should not have default Description' {
            $help.Description.Text | Should -Not -Be 'Long description'
        }

        # Should be a description for every function
        It 'Should have description' {
            $help.Description.Text | Should -Not -BeNullOrEmpty
        }

        # Should be at least one example
        It 'Should have at least one example' {
            ($help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
        }

        # Each example should have a code snippet
        It 'Should have example code for each example' {
            $help.Examples.Example.Code | Where-Object { $_ } | ForEach-Object {
                $exampleCode = $_
                $exampleCode | Should -Not -BeNullOrEmpty
            }
        }

        # Each example should call the tested command
        It 'Should have correct command called in each example' {
            Set-ItResult -Skipped -Because "Get-Help examples do not support multi-line code blocks"
            $help.Examples.Example | Where-Object { $_ } | ForEach-Object {
                $exampleCode = $_.Code
                $exampleCode | Should -BeLike "*$CommandName*"
            }
        }

        # Each example should have a description
        It 'Should have example description for each example' {
            $help.Examples.Example | Where-Object { $_ } | ForEach-Object {
                $exampleRemarksText = $_.Remarks.Text
                $exampleRemarksText | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Parameter Help for [<CommandName>:<ParameterName>]' -Foreach $commandParametersTestCases {
        # Should be a description for every parameter
        It 'Should have help for parameter [<ParameterName>]' {
            if ($Parameter.IsDynamic) {
                Set-ItResult -Skipped -Because (
                    "`n" +
                    "Dynamic parameters disappear from Get-Help output if comment-based help is present in the script.`n" +
                    "https://info.sapien.com/index.php/scripting/scripting-help/writing-help-for-dynamic-parameters"
                )
            } else {
                $ParameterHelp.Description.Text | Should -Not -BeNullOrEmpty
            }
        }

        # Required value in Help should match IsMandatory property of parameter
        It 'Should have correct Mandatory value for parameter [<ParameterName>] for [<CommandName>]' {
            if ($Parameter.IsDynamic) {
                Set-ItResult -Skipped -Because (
                    "`n" +
                    "Dynamic parameters disappear from Get-Help output if comment-based help is present in the script.`n" +
                    "https://info.sapien.com/index.php/scripting/scripting-help/writing-help-for-dynamic-parameters"
                )
            } else {
                $codeMandatory = $Parameter.IsMandatory.toString()
                $ParameterHelp.Required | Should -Be $codeMandatory
            }
        }
    }

    Context 'Help Links' {
        # Should have a valid uri if one is provided.
        It 'Should be a valid link [<Link>] for [<CommandName>]' -TestCases $linksTestCases {
            $uri = $Link -as [System.URI]
            $uri.AbsoluteURI | Should -Not -BeNullOrEmpty
            $uri.Scheme | Should -Match '[http|https]'
        }
    }

}
