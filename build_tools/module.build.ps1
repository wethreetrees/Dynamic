Param(
    [string]$ModuleName,
    [switch]$Coverage,
    [double]$MinimumCoverage,
    [switch]$CI
)

# Synopsis: Runs full Build and Test process
Task Default Build, Test

# Synopsis: Builds the [dist] directory and prepares the module for testing and publishing
Task Build Clean, CopyDist, GetReleasedModuleInfo, BuildPSM1, BuildPSD1

# Synopsis: Runs a new build and imports the resulting module
Task Import Build, {
    Write-Output "  Removing loaded module [$ModuleName]"
    Remove-Module -Name $ModuleName -Force -Verbose:$VerbosePreference -ErrorAction SilentlyContinue
    Write-Output "  Import module from path [$Script:ManifestPath]"
    Import-Module -Name $Script:ManifestPath -Force -Verbose:$VerbosePreference
}

Enter-Build {

    function GetPreviousRelease {
        [CmdletBinding()]
        Param (
            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [string]$Path
        )

        process {
            try {
                $module = Find-Module -Name $Name -Repository PSGallery -ErrorAction SilentlyContinue
                if ($module) {
                    $module | Save-Module -Path $Path -Force
                    $module
                }
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }

    function GetPublicFunctionInterfaces {
        [CmdletBinding()]
        Param (
            [System.Management.Automation.FunctionInfo[]]$FunctionList
        )

        $functions = @{}

        $FunctionList | ForEach-Object {
            $function = $_

            $Parameters = @{}

            $function.Parameters.Keys | ForEach-Object {
                $parameterName = $_
                $parameter = $function.Parameters[$parameterName]
                $parameterAttribute = $parameter.Attributes | where {$_ -is [System.Management.Automation.ParameterAttribute]}
                $allowEmptyString = ($parameter.Attributes | ForEach-Object { $_.GetType().Name }) -contains 'AllowEmptyStringAttribute'
                $allowNull = ($parameter.Attributes | ForEach-Object { $_.GetType().Name }) -contains 'AllowNullAttribute'

                $paramInfo = [pscustomobject]@{
                    Type = $parameter.ParameterType.Name
                    Attributes = [pscustomobject]@{
                        Position = $parameterAttribute.Position
                        Mandatory = $parameterAttribute.Mandatory
                        AllowEmptyString = $allowEmptyString
                        AllowNull = $allowNull
                        ValueFromPipeline = $parameterAttribute.ValueFromPipeline
                        ValueFromPipelineByPropertyName = $parameterAttribute.ValueFromPipelineByPropertyName
                        ValueFromRemainingArguments = $parameterAttribute.ValueFromRemainingArguments
                    }
                    Aliases = [string[]]$parameter.Aliases
                }

                $Parameters[$parameterName] = $paramInfo
            }

            $functions[$function.Name] = $Parameters
        }

        $functions
    }

    function ComparePublicFunctionInterfaces {
        param (
            $NewInterfaces,
            $OldInterfaces
        )

        Compare-Object -ReferenceObject $OldInterfaces -DifferenceObject $NewInterfaces
    }

    function GetModifiedFiles {
        param (
            [string]$ReferenceFolder,
            [string]$DifferenceFolder,
            [string[]]$Exclude
        )
        $Exclude = $Exclude | ForEach-Object { $_ -replace '\\','\\' }
        $ReferenceHashes = Get-ChildItem -Path "$ReferenceFolder" -Recurse |
            Where-Object { $_.FullName -notmatch ($Exclude -join '|') -and $_ -is [System.IO.FileInfo] } |
            ForEach-Object {
                $content = Get-Content $_.FullName
                $content | Set-Content $_.FullName
                $_.FullName
            } | ForEach-Object { Get-FileHash -Path $_ }
        $DifferenceHashes = Get-ChildItem -Path "$DifferenceFolder" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch ($Exclude -join '|') -and $_ -is [System.IO.FileInfo] } |
            ForEach-Object {
                $content = Get-Content $_.FullName
                $content | Set-Content $_.FullName
                $_.FullName
            } | ForEach-Object { Get-FileHash -Path $_ }
        $files = $ReferenceHashes + $DifferenceHashes

        foreach ($ReferenceHash in $ReferenceHashes) {
            foreach ($DifferenceHash in $DifferenceHashes) {
                if ($ReferenceHash.Hash -eq $DifferenceHash.Hash) {
                    $files = $files | Where-Object { $_.Path -ne $ReferenceHash.Path }
                    $files = $files | Where-Object { $_.Path -ne $DifferenceHash.Path }
                }
            }
        }

        $files | ForEach-Object { ($_.Path -split '\\')[-1] } | Select-Object -Unique
    }

    $Script:ProjectPath = Split-Path -Path $PSScriptRoot -Parent -Resolve
    $Script:BuildTools = Join-Path -Path $Script:ProjectPath -ChildPath build_tools
    $Script:BuildDependencies = Join-Path -Path $Script:ProjectPath -ChildPath "$Script:BuildTools\_build_dependencies_"
    $Script:Docs = Join-Path -Path $Script:ProjectPath -ChildPath docs
    $Script:Source = Join-Path -Path $Script:ProjectPath -ChildPath src
    $Script:Build = Join-Path -Path $Script:ProjectPath -ChildPath build
    $Script:Dist = Join-Path -Path $Script:ProjectPath -ChildPath dist
    $Script:Destination = Join-Path -Path $Script:Dist -ChildPath $Script:ModuleName
    $Script:ModulePath = Join-Path -Path $Script:Destination -ChildPath "$Script:ModuleName.psm1"
    $Script:ReleasedModulePath = Join-Path -Path $Script:Build -ChildPath 'releasedModule'
    $Script:ManifestPath = Join-Path -Path $Script:Destination -ChildPath "$Script:ModuleName.psd1"
    $Script:ModuleDependencies = Join-Path -Path $Script:Destination -ChildPath 'Modules'
    $Script:ModuleTests = Join-Path -Path $Script:ProjectPath -ChildPath tests
    $Script:CommonTests = Join-Path -Path $Script:ProjectPath -Childpath build_tools\tests
    $Script:Tests = @(
        $Script:ModuleTests
        $Script:CommonTests
    )
    $Script:Imports = ('public', 'private')
    $Script:Classes = (Get-ChildItem -Path "$Script:Source\classes" -ErrorAction SilentlyContinue).Name
    $Script:NeedsPublished = $false
    $Script:IsPromotion = $false
}

# Synopsis: Remove any existing build files
Task Clean {
    remove $Script:Build
    remove $Script:Dist
}

# Synopsis: Copy files and directories to the dist directory for testing/publishing
Task CopyDist {
    Write-Output "  Creating directory [$Script:Destination]"
    New-Item -Type Directory -Path $Script:Build -ErrorAction SilentlyContinue | Out-Null
    New-Item -Type Directory -Path $Script:Dist -ErrorAction SilentlyContinue | Out-Null
    New-Item -Type Directory -Path $Script:Destination -ErrorAction SilentlyContinue | Out-Null
    New-Item -Type Directory -Path $Script:Docs -ErrorAction SilentlyContinue | Out-Null

    Write-Output "  Files and directories to be copied from source [$Script:Source]"

    Get-ChildItem -Path $Script:Source -File |
        Where-Object -Property Name -NotMatch "$Script:ModuleName\.ps[md]1" |
        Copy-Item -Destination $Script:Destination -Force -PassThru |
        ForEach-Object {"   Creating file [{0}]" -f $_.fullname.replace($PSScriptRoot, '')}

    Get-ChildItem -Path $Script:Source -Directory |
        Copy-Item -Destination $Script:Destination -Recurse -Force -PassThru |
        ForEach-Object {"   Creating directory (recursive) [{0}]" -f $_.fullname.replace($PSScriptRoot, '')}
}

# Synopsis: Get the latest module release
Task GetReleasedModuleInfo {
    if (-not (Test-Path $Script:ReleasedModulePath)) {
        $null = New-Item -Path $Script:ReleasedModulePath -ItemType Directory
    }

    $getPreviousReleaseParams = @{
        Name          = $Script:ModuleName
        Path          = $Script:ReleasedModulePath
    }
    $release = GetPreviousRelease @getPreviousReleaseParams

    if ($release) {
        # Run in a job so we don't pollute the current session with released module version import
        $initScriptBlock = [scriptblock]::create(@"
Set-Location '$Script:ProjectPath'
function GetPublicFunctionInterfaces {$function:GetPublicFunctionInterfaces}
"@)
        $ScriptBlock = {
            $releasedModule = Import-Module -Name "$Using:ReleasedModulePath\$Using:ModuleName" -PassThru -Force -ErrorAction Stop

            $releasedModuleManifestPath = "$Using:ReleasedModulePath\$Using:ModuleName\*\$Using:ModuleName.psd1"
            $prereleaseValue = Get-ManifestValue -Path $releasedModuleManifestPath -PropertyName Prerelease
            $functionList = $releasedModule.ExportedFunctions.Values

            [PSCustomObject] @{
                Name = $releasedModule.Name
                Prerelease = $prereleaseValue -ne ''
                Version = $releasedModule.Version
            }
        }

        $Script:releasedModuleInfo = Start-Job -ScriptBlock $ScriptBlock -InitializationScript $initScriptBlock |
            Receive-Job -Wait -AutoRemoveJob

        Write-Output "  Found release [$($release.version)] for $Script:ModuleName"
    } else {
        Write-Warning (
            "No previous release found. If this is not a new module, follow the below steps:`n" +
            "    - Check the PSGallery nuget key`n" +
            "    - Check your internet connection`n" +
            "    - Check that the previous release has not been delisted or deleted"
        )
    }
}

# Synopsis: Generate the module psm1 file
Task BuildPSM1 {
    [System.Text.StringBuilder]$StringBuilder = [System.Text.StringBuilder]::new()
    foreach ($class in $Script:Classes) {
        Write-Output "  Found $class"
        [void]$StringBuilder.AppendLine("using module 'Classes\$class'")
    }

    Push-Location -Path $Script:Destination
    try {
        $modules = (Get-ChildItem -Path "$Script:ModuleDependencies" -Recurse -Filter *.psd1).FullName
        foreach ($module in $modules) {
            $relativeModulePath = ($module | Resolve-Path -Relative).Substring(1)
            Write-Output "  Found $relativeModulePath"
            [void]$StringBuilder.AppendLine("")
            [void]$StringBuilder.AppendLine("Import-Module `"`$PSScriptRoot$relativeModulePath`" -Force")
        }
    } finally {
        Pop-Location
    }

    foreach ($folder in $Script:Imports)
    {
        [void]$StringBuilder.AppendLine("")
        [void]$StringBuilder.AppendLine("Write-Verbose `"Importing from [`$PSScriptRoot\$folder]`"")
        if (Test-Path "$Script:Source\$folder")
        {
            $fileList = Get-ChildItem "$Script:Source\$folder" -Filter '*.ps1'
            foreach ($file in $fileList)
            {
                $importName = "$folder\$($file.Name)"
                Write-Output "  Found $importName"
                [void]$StringBuilder.AppendLine( ". `"`$PSScriptRoot\$importName`"")
            }
        }
    }

    [void]$StringBuilder.AppendLine("")
    [void]$StringBuilder.AppendLine("`$publicFunctions = (Get-ChildItem -Path `"`$PSScriptRoot\public`" -Filter '*.ps1').BaseName")
    [void]$StringBuilder.AppendLine("")
    [void]$StringBuilder.AppendLine("Export-ModuleMember -Function `$publicFunctions")

    Write-Output "  Creating module [$Script:ModulePath]"
    Set-Content -Path $Script:ModulePath -Value $stringbuilder.ToString()
}

# Synopsis: Generate the module psd1 file
Task BuildPSD1 {
    Write-Output "  Updating [$Script:ManifestPath]"
    Copy-Item "$Script:Source\$Script:ModuleName.psd1" -Destination $Script:ManifestPath

    # Get dependency dlls, by relative path, and update RequiredAssemblies property
    Write-Output "  Detecting RequiredAssemblies"
    Push-Location $Script:Destination
    $dlls = Get-ChildItem "Modules" -Recurse -Filter *.dll | Resolve-Path -Relative
    Pop-Location
    if ($dlls) { Update-Metadata -Path $Script:ManifestPath -PropertyName RequiredAssemblies -Value $dlls }

    Write-Output "  Setting Module Functions"
    $moduleFunctions = Get-ChildItem -Path "$Script:Source\public" -Filter '*.ps1' | Select-Object -ExpandProperty BaseName
    Update-Metadata -Path $Script:ManifestPath -Property FunctionsToExport -Value $moduleFunctions

    Write-Output "  Setting ProjectUri"
    $ProjectUri = Invoke-Git config --get remote.origin.url
    if ($ProjectUri) { Update-Metadata $Script:ManifestPath -Property ProjectUri -Value $ProjectUri }

    Write-Output "  Setting Custom Formats"
    Push-Location -Path $Script:Destination
    $moduleFormats = Get-ChildItem -Path ".\Formats" -Filter '*.ps1xml' -ErrorAction SilentlyContinue | Resolve-Path -Relative
    if ($moduleFormats) { Update-Metadata -Path $Script:ManifestPath -Property FormatsToProcess -Value $moduleFormats }
    Pop-Location

    if ($Script:releasedModuleInfo) {
        Write-Output "  Detecting Module File Changes"
        $excludedFilesList = @(
            "$($Script:ModuleName).psd1",
            "$($Script:ModuleName)\Modules",
            ".xml",
            ".rels",
            ".psmdcp",
            ".nuspec",
            ".nupkg"
        )
        $GetModifiedFilesParams = @{
            ReferenceFolder = $Script:Destination
            DifferenceFolder = "$($Script:ReleasedModulePath)\$($Script:ModuleName)\*\"
            Exclude = $excludedFilesList
        }
        $changedFiles = GetModifiedFiles @GetModifiedFilesParams
        if ($changedFiles) {
            $changedFiles | ForEach-Object { "    $_" }
            $DetectedVersionIncrement = 'Patch'
        }

        Write-Output "  Detecting Function Interface Changes"
        # Run in a job so we don't pollute the current session with released module version import
        $initScriptBlock = [scriptblock]::create(@"
Set-Location '$Script:ProjectPath'
function GetPublicFunctionInterfaces {$function:GetPublicFunctionInterfaces}
"@)
        $scriptBlock = {
            # Detecting ReleasedModule Functions
            $releasedModule = "$Using:ReleasedModulePath\$Using:ModuleName"

            if (Test-Path -Path $releasedModule) {
                $oldFunctionList = (Import-Module -Name $releasedModule -Force -PassThru).ExportedFunctions.Values
                $oldFunctionInterfaces = GetPublicFunctionInterfaces -FunctionList $oldFunctionList

                # Detecting Current Module Functions
                $newFunctionList = (Import-Module -Name "$Using:ManifestPath" -Force -PassThru).ExportedFunctions.Values
                $newFunctionInterfaces = GetPublicFunctionInterfaces -FunctionList $newFunctionList

                # TestHelpers defines a new Pester assertion, so we need to make sure Pester is loaded
                if (-not (Invoke-PSDepend -Path "$Using:BuildTools\build.Depend.psd1" -Tags Test -Test -Quiet)) {
                    Invoke-PSDepend -Path "$Using:BuildTools\build.Depend.psd1" -Tags Test -Install -Force
                }
                Invoke-PSDepend -Path "$Using:BuildTools\build.Depend.psd1" -Tags Test -Import -Force
                Import-Module $Using:BuildTools\tests\TestHelpers.psm1 -DisableNameChecking
                Compare-PSObject -ReferenceObject $oldFunctionInterfaces -DifferenceObject $newFunctionInterfaces
            }
        }
        $functionInterfaceComparison = Start-Job -ScriptBlock $ScriptBlock -InitializationScript $initScriptBlock |
            Receive-Job -Wait -AutoRemoveJob -ErrorAction SilentlyContinue -ErrorVariable err |
            Select-Object -Property * -ExcludeProperty RunspaceId, PSComputerName, PSShowComputerName, PSSourceJobInstanceId

        foreach ($e in $err) {
            # Ignoring argument validator errors. These have only been encountered with dynamic parameter
            # functions that have mandatory arguments with validators.
            if ($e -and $e.exception.message -notlike 'Cannot validate argument on parameter*') {
                throw $e
            }
        }

        if ($err) {
            Write-Warning "Encountered Validator Errors (Not critical, but you may want to investigate)"
            $err | Select-Object -Unique | ForEach-Object {
                Write-Output $_
            }
        }

        if ($functionInterfaceComparison) {
            Write-Output "  Detecting New Features"
            if ($null -in $functionInterfaceComparison.ReferenceValue) {
                $DetectedVersionIncrement = 'Minor'
                $newFeatures = $functionInterfaceComparison | Where-Object { $null -eq $_.ReferenceValue }
                Write-Output "    Detected New Features"
                Write-Output "      $($newFeatures | Out-String)"
            }
        }

        if ($functionInterfaceComparison) {
            Write-Output "  Detecting Lost Features (breaking changes)"
            if ($null -in $functionInterfaceComparison.DifferenceValue) {
                $DetectedVersionIncrement = 'Major'
                Write-Output "    Detected Lost Features"
                $lostFeatures = $functionInterfaceComparison | Where-Object { $null -eq $_.DifferenceValue }
                Write-Output "      $($lostFeatures | Out-String)"
            }
            $mandatoryActivated = $functionInterfaceComparison | Where-Object {
                $_.Property -like '*.Mandatory' -and $_.ReferenceValue -eq $false -and $_.DifferenceValue -eq $true
            }
            if ($mandatoryActivated) {
                $DetectedVersionIncrement = 'Major'
                Write-Output "    Detected 'Mandatory' Property Changes"
                Write-Output "      $($mandatoryActivated | Out-String)"
            }
            $otherBreakingChange = $functionInterfaceComparison | Where-Object {
                ($_.Property -like '*.AllowEmptyString' -and $_.ReferenceValue -eq $true -and $_.DifferenceValue -eq $false) -or
                ($_.Property -like '*.AllowNull' -and $_.ReferenceValue -eq $true -and $_.DifferenceValue -eq $false) -or
                ($_.Property -like '*.ValueFromPipeline' -and $_.ReferenceValue -eq $true -and $_.DifferenceValue -eq $false) -or
                ($_.Property -like '*.ValueFromPipelineByPropertyName' -and $_.ReferenceValue -eq $true -and $_.DifferenceValue -eq $false) -or
                ($_.Property -like '*.ValueFromRemainingArguments' -and $_.ReferenceValue -eq $true -and $_.DifferenceValue -eq $false)
            }
            if ($otherBreakingChange) {
                $DetectedVersionIncrement = 'Major'
                Write-Output "    Detected Other Breaking Changes"
                Write-Output "      $($otherBreakingChange | Out-String)"
            }
        }
    }

    $version = [Version](Get-Metadata -Path $Script:ManifestPath -PropertyName ModuleVersion)

    # Don't bump major version if in pre-release
    if ($version -lt ([Version]"1.0.0")) {
        if ($DetectedVersionIncrement -eq 'Major') {
            $DetectedVersionIncrement = 'Minor'
        }
    }

    $releasedVersion = $Script:releasedModuleInfo.Version
    $releaseIsPrerelease = $Script:releasedModuleInfo.Prerelease

    if ($version -gt $releasedVersion) {
        $Script:NeedsPublished = $true
        $relativeManifestPath = "$Script:Source\$Script:ModuleName.psd1" | Resolve-Path -Relative
        Write-Output "  Detected manual version increment, using version from $($relativeManifestPath): [$version]"
        $Script:NeedsPublished = $true
    } elseif (-not $Prerelease -and $releaseIsPrerelease -and -not $DetectedVersionIncrement) {
        $version = $releasedVersion
        Write-Output "  Promoting [$version] to release!"
        $Script:NeedsPublished = $true
    } elseif ($DetectedVersionIncrement) {
        $version = [Version](Step-Version -Version $releasedVersion -By $DetectedVersionIncrement)
        Write-Output "  Stepping module from released version [$releasedVersion] to new version [$version] by [$DetectedVersionIncrement] revision"
        $Script:NeedsPublished = $true
    } else {
        Write-Output "No changes detected, using version from released version [$releasedVersion]"
        $version = $releasedVersion
    }

    Update-Metadata -Path $Script:ManifestPath -PropertyName 'ModuleVersion' -Value $version

    if ($Prerelease) {
        Update-Metadata -Path $Script:ManifestPath -PropertyName Prerelease -Value 'prerelease'
    }
}

# Synopsis: Alias for Pester task
Task Test Pester

# Synopsis: Execute Pester tests
Task Pester {
    if (-not (Test-Path -Path $Script:Destination)) {
        throw "You must run the 'Build' task before running the test suite!`nTry this: .\build.ps1 -Task Build, Test`n Or this: .\build.ps1"
    }

    if (-not (Test-Path -Path $Script:Build)) {
        New-Item -Type Directory -Path $Script:Build -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Output "  Setting up test dependencies"

    if (-not (Invoke-PSDepend -Path "$Script:BuildTools\build.Depend.psd1" -Tags Test -Test -Quiet)) {
        Invoke-PSDepend -Path "$Script:BuildTools\build.Depend.psd1" -Tags Test -Install -Force
    }
    Invoke-PSDepend -Path "$Script:BuildTools\build.Depend.psd1" -Tags Test -Import -Force

    # # We are importing this here, instead of in our tests for two reasons
    # #   1. Pester has a bug where mocks leak into other imported modules when imported into the same session
    # #   2. This way we also do not need to import these helpers in each test script
    Import-Module -Name $Script:BuildTools\tests\TestHelpers.psm1 -Force -DisableNameChecking

    Get-Module -All -Name $Script:ModuleName | Remove-Module -Force -ErrorAction SilentlyContinue

    $coveragePaths = $Script:Imports | ForEach-Object {
        $validatePath = "$Script:Destination\$_\*.ps1"
        if (Get-ChildItem -Path $validatePath -ErrorAction SilentlyContinue) {
            $validatePath
        }
    }

    Write-Output "  Setting up test configuration"
    $configuration                                    = New-PesterConfiguration
    $configuration.Run.Path                           = @($Script:Tests)
    $configuration.Output.Verbosity                   = 'Normal'
    $configuration.Run.PassThru                       = $true
    $configuration.TestResult.Enabled                 = $true
    $configuration.TestResult.OutputPath              = "$Script:Build\testResults.xml"
    $configuration.Should.ErrorAction                 = 'SilentlyContinue'
    $configuration.CodeCoverage.Enabled               = $Script:Coverage.IsPresent
    $configuration.CodeCoverage.Path                  = $coveragePaths
    $configuration.CodeCoverage.OutputFormat          = if ($CI) { 'JaCoCo' } else { 'CoverageGutters' }
    $configuration.CodeCoverage.OutputPath            = "$Script:Build\coverage.xml"
    $configuration.CodeCoverage.CoveragePercentTarget = $MinimumCoverage
    Write-Output "  Starting Pester tests"
    $pesterResults = Invoke-Pester -Configuration $configuration -Verbose:$VerbosePreference

    assert ($pesterResults) "There was a terminal error when executing the Pester tests."
    assert (-not $pesterResults.FailedCount) "There were $($pesterResults.FailedCount) Pester test failures!"
    assert ($pesterResults.CodeCoverage.CoveragePercent -ge $pesterResults.CodeCoverage.CoveragePercentTarget) "Code coverage policy failed."
}

# Synopsis: Publish module, if needed
Task Publish GetReleasedModuleInfo, {
    if (-not (Test-Path -Path $Script:Destination)) {
        throw "You must run the 'Build' task before publishing the module!`nTry this: .\build.ps1 -Task Build"
    }

    $releasedModuleManifest = Import-PowerShellDataFile -Path "$($Script:ReleasedModulePath)\$ModuleName.psd1" -ErrorAction SilentlyContinue
    $buildModuleManifest = Import-PowerShellDataFile -Path "$($Script:Destination)\$ModuleName.psd1"

    if ($releasedModuleManifest.ModuleVersion -lt $buildModuleManifest.ModuleVersion) {
        Write-Output "  Publishing $($ModuleName):$($buildModuleManifest.ModuleVersion) to the PSGallery"
        Publish-Module -Path $Script:Destination -Repository PSGallery -NuGetApiKey $env:NUGET_KEY -Verbose
    } else {
        Write-Output "  Build does not need to be published"
    }
}

# Synopsis: Create Pester test scripts for existing functions that are missing Pester tests
Task GenerateTestFiles {
    $functionTypes = 'public', 'private'

    $functionTypes | ForEach-Object {
        $functionType = $_

        # Get module functions
        $functionScripts = Get-ChildItem -Path "$Script:Source\$functionType" -Filter '*.ps1' -Recurse
        $functionList = $functionScripts.Name -replace '.ps1'

        $testScripts = Get-ChildItem -Path "$Script:ModuleTests\$functionType" -Filter '*.ps1' -Recurse
        $testList = $testScripts.Name -replace '.Tests.ps1'

        foreach ($function in $functionList) {
            if ($function -notin $testList) {
                $invokePlasterParams = @{
                    TemplatePath    = "$Script:BuildTools\templates\FunctionTest"
                    ModuleName      = $Script:ModuleName
                    FunctionName    = $function
                    FunctionType    = $functionType
                    DestinationPath = $Script:ModuleTests
                    NoLogo          = $true
                }
                Invoke-Plaster @invokePlasterParams
            }
        }
    }
}

# Synopsis: Create a new module function script
Task NewFunction {
    $invokePlasterParams = @{
        TemplatePath    = "$Script:BuildTools\templates\ModuleFunction"
        ModuleName      = $Script:ModuleName
        DestinationPath = $Script:Source
        NoLogo          = $true
    }
    Invoke-Plaster @invokePlasterParams
}, GenerateTestFiles