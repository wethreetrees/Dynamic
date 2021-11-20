# 💬 How to contribute

Please first look over the `CODE_OF_CONDUCT.md` for community guidelines. Below are a few items to assist in creating any code contributions to **Dynamic**.

If you see any areas for improvement, please [open an issue](https://github.com/wethreetrees/Dynamic/issues/new/choose) or [submit a pull request](https://github.com/wethreetrees/Dynamic/compare)! While I am technically accepting Pull Requests, my schedule is very full, so it may take some time to review and approve any propsed changes.

If a particular issue or enhancement request receives significant community backing, it will be more likely to be prioritized.

## Setup

Fork the repo by following the steps [here](https://docs.github.com/en/get-started/quickstart/fork-a-repo).

Clone the fork to your machine and run

```powershell
./build.ps1 -Task Build, Test, Import
```

Whenever changes are made to the `src` directory, run the above build command again in order to rebuild and import the changes into the current PowerShell session.

## Adding a new test case

Always be on the lookout for new test cases!

***Full code coverage != Full use case coverage***

When adding functionailty, fixing a bug, or even just perusing the source code, if you identify a gap in *use case* coverage, add a test case! You can reference the [WriteHello Test Module](./tests/resources/WriteHello) and the existing [tests](./tests) for examples on how to structure any new cases.

1. Create a new script, utilizing the `[Dynamic()]` parameter attribute
2. Run the following commands to get the function info and generate the *expected* result, replacing the path and function name to match your new function
```powershell
# Load the new function script into the current PowerShell session
. "./tests/resources/WriteHello/public/Write-Hello.ps1"

# Get the function info
$functionInfo = Get-Command -Name Write-Hello

# Import the Dynamic module
Import-Module ./Dynamic.psd1 -Force

# Compile the expected output to the FunctionDefinitions directory
Resolve-DynamicFunctionDefinition -FunctionInfo $functionInfo | Set-Content -Path "./tests/resources/FunctionDefinitions/Write-Hello.dyndef.ps1" -NoNewLine
```

This will get you started on the path to covering the use case. Once this is completed, make sure to add any test cases needed for testing the test function/module code.

## New module functions

If you have a recommendation for a new module function, please [open an enhancement request](https://github.com/wethreetrees/Dynamic/issues/new/choose) before implementing a change and submitting a pull request 🙏.
