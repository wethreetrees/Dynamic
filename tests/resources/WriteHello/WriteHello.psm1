using module ../../../PsDynParam.psd1

$public = Get-ChildItem -Path $PSScriptRoot/public -Filter *.ps1 -ErrorAction SilentlyContinue
$private = Get-ChildItem -Path $PSScriptRoot/private -Filter *.ps1 -ErrorAction SilentlyContinue

foreach ($script in $private) {
    . $script
}

foreach ($script in $public) {
    . $script.FullName

    $functionInfo = Get-Command -Name Write-Hello

    . (Set-DynamicParameterDefinition -FunctionInfo $functionInfo)
}

Export-ModuleMember -Function $public.BaseName