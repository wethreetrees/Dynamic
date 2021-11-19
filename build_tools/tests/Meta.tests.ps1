BeforeDiscovery {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'MetaFixers.psm1') -Verbose:$false -Force
    $moduleProjectPath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    $moduleName = (get-item $moduleProjectPath).BaseName
    $allTextFiles = Get-TextFilesList $moduleProjectPath -Exclude '_build_dependencies_', "$moduleName\\Modules", '\\build\\'
}

Describe 'Text file formatting - <_>' -ForEach $allTextFiles {

    It "Doesn't use Unicode encoding" {
        if ($unicode = Test-FileUnicode $_) {
            Write-Warning "File $($_.FullName) contains 0x00 bytes. It's probably uses Unicode and need to be converted to UTF-8. Use Fixer 'Get-UnicodeFilesList `$pwd | ConvertTo-UTF8'."
        }
        $unicode | Should -Be $false
    }
    It 'Uses spaces for indentation, not tabs' {
        $fileName = $_.FullName
        if ($tabs = (Get-Content $fileName) | Select-String "`t") {
            Write-Warning "There are tabs in $fileName. Use Fixer 'Get-TextFilesList `$pwd | ConvertTo-SpaceIndentation'."
            $tabs.LineNumber | ForEach-Object {
                Write-Warning "Found tab(s) on line $_"
            }
        }
        $tabs.Count | Should -Be 0
    }

}
