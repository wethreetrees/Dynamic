class ThrowTerminatingError : System.Attribute {}

# . $PSScriptRoot/decorators/ThrowTerminatingError.ps1

. "$PSScriptRoot/public/Write-Hello.ps1"
# . $commandPath
# $command = Get-Command -Name "Write-Hello"
# if ($command.ScriptBlock.Attributes.TypeId.Name -contains 'ThrowTerminatingError') {
#     ThrowTerminatingErrorProxy -Name $command.Name -CommandInfo $command
# }

. $PSScriptRoot/Set-DynamicParameterDefinition.ps1

$functionInfo = Get-Command -Name Write-Hello

Set-DynamicParameterDefinition -FunctionInfo $functionInfo | Set-Content -Path $PSScriptRoot/test.ps1 -Force

. $PSScriptRoot/test.ps1

Export-ModuleMember -Function Write-Hello