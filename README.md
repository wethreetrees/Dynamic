## Contributing

### Adding a new test case

1. Create a new script, utilizing the `[Dynamic()]` parameter attribute
2. Run the following commands to get the function info and generate the *expected* result, replacing the path and function name to match your new function
```ps
# Load the new function script into the current PowerShell session
. "./tests/resources/WriteHello/public/Write-Hello.ps1"

# Get the function info
$functionInfo = Get-Command -Name Write-Hello

# Import the PSDynParam module
Import-Module ./PSDynParam.psd1 -Force

# Compile the expected output to the FunctionDefinitions directory
Set-DynamicParameterDefinition -FunctionInfo $functionInfo | Set-Content -Path "./tests/resources/FunctionDefinitions/Write-Hello.dyndef.ps1" -NoNewLine
```