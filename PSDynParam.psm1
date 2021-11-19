$public = Get-ChildItem -Path $PSScriptRoot/public -Filter *.ps1 -ErrorAction SilentlyContinue
$private = Get-ChildItem -Path $PSScriptRoot/private -Filter *.ps1 -ErrorAction SilentlyContinue

foreach ($script in $private) {
    . $script.FullName
}

foreach ($script in $public) {
    . $script.FullName
}

Export-ModuleMember -Function $public.BaseName