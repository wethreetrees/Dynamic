[![PowerShell Gallery Version (including pre-releases)](https://img.shields.io/powershellgallery/v/Dynamic?include_prereleases&style=flat-square)](https://www.powershellgallery.com/packages/Dynamic)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/Dynamic?style=flat-square)](https://www.powershellgallery.com/packages/Dynamic)
[![GitHub last commit (branch)](https://img.shields.io/github/last-commit/wethreetrees/Dynamic/master?style=flat-square)](https://github.com/wethreetrees/Dynamic/commit/master)
[![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/wethreetrees/Dynamic/CICD/master?style=flat-square)](https://github.com/wethreetrees/Dynamic/actions)


# ✨ Dynamic ✨

Working with dynamic parameters in PowerShell has never been *easy*. The **Dynamic** module will change that forever.

In the past, developers were required to have an advanced knowledge of PowerShell and experience using .NET objects to even get started with dynamic parameters. **Tons** of great documentation exists, in the community, to provide step-by-step instructions for defining and using dynamic parameters, but it still ***feels*** bad.

```powershell
# The PAST (╯°□°）╯︵ ┻━┻
function Write-Hello
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        $Name = 'World'
    )

    dynamicparam
    {
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        if (
            $null -eq $PSBoundParameters['Name']
        ) {
            $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

            $attrib = [Parameter]::new()
            $attrib.Mandatory=$true
            $attributeCollection.Add($attrib)

            $attrib = [ValidateSet]::new('Mercury','Venus','Earth','Mars','Jupiter','Saturn','Uranus','Neptune')
            $attributeCollection.Add($attrib)

            $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('Planet',[string],$attributeCollection)

            $paramDictionary.Add('Planet',$dynParam)
        }

        $paramDictionary
    }

    begin {

        if($PSBoundParameters.ContainsKey('Planet')) { $Planet = $PSBoundParameters['Planet'] }
        else { $Planet = $null}

    }

    process {
        Write-Output "Hello, $Name!"
        if ($Planet) {
            Write-Output "Welcome to $Planet!"
        }
    }
}
```

**Dynamic** enables PowerShell developers to naturally define dynamic parameters in the param blocks of their existing functions, as it should be.

```powershell
# The FUTURE (⌐■_■)
function Write-Hello {
    [CmdletBinding()]
    param (
        [Parameter()]
        $Name = 'World',

        [Parameter(Mandatory)]
        [Dynamic({
            $null -eq $PSBoundParameters['Name']
        })]
        [ValidateSet(
            'Mercury',
            'Venus',
            'Earth',
            'Mars',
            'Jupiter',
            'Saturn',
            'Uranus',
            'Neptune'
        )]
        [string]$Planet
    )

    process {
        Write-Output "Hello, $Name!"
        if ($Planet) {
            Write-Output "Welcome to $Planet!"
        }
    }

}
```

![feels_good](https://github.com/wethreetrees/Dynamic/blob/master/.images/feels_good.jpg)

> Defining dynamic parameters should ***feel good***.

– wethreetrees

## 💻 Installation

Install the latest release from the [PSGallery](https://www.powershellgallery.com/packages/Dynamic)

```powershell
Install-Module -Name Dynamic -Repository PSGallery
```

### Updating

Update **Dynamic** using `Update-Module`

```powershell
Update-Module -Name Dynamic
```

### Local Development

You can also build the module yourself. The build script has many options, which can be discovered with the following command:

```powershell
./build.ps1 -Task ?
```

Run a typical build, with tests and coverage

```powershell
./build.ps1 -Coverage
```

Run the default build tasks and import the built module

```powershell
./build.ps1 -Task Import
```

## 🧩 Integration

To integrate the **Dynamic** standard for dynamic parameter definitions, you can follow three distinct paths.

### 🐱‍👤 Full Integration

For full integration, it is recommended to run **Dynamic** as part of your ci/cd pipeline.

You can follow the same steps illustrated in the *Advanced Integration* method, but before you write out your function scripts to your `dist` directory.

This gives you the benefit of fully supported `[Dynamic()]` attributes as well as full IDE debug support, by setting breakpoints in your function definitions located in the `dist` directory.

### ⚙ Advanced Integration

*Reference:*  [WriteHello Test Module](./tests/resources/TestModules/WriteHello/WriteHello.psm1)

You can *overwrite* your existing function defintions in memory while loading your module. This is a highly recommended method, but you lose the ability to debug your function scripts in your IDE. So it will always be recommended to integrate using the full integration method above.

In most `psm1` files, you will be doing something like this:

```powershell
$public = Get-ChildItem -Path $PSScriptRoot/public -Filter *.ps1

foreach ($script in $public) {
    . $script
}
```

To integrate with **Dynamic**, you only have to add two lines of code:

```powershell
$public = Get-ChildItem -Path $PSScriptRoot/public -Filter *.ps1

foreach ($script in $public) {
    . $script.FullName

    $functionInfo = Get-Command -Name $script.BaseName

    . (Resolve-DynamicFunctionDefinition -FunctionInfo $functionInfo)
}
```

### 📎 Simple Integration

The simple integration method can be used to write new scripts or convert existing scripts to easily define new dynamic parameters.

***Note: This method is a one-way process and not strictly recommended***

You will begin with a function definition and end with a **final** result, saved forever in your project. This is not necessarily the *best* approach, as you lose the advantages of full integration, listed above.

This example will define a function with a new `[Dynamic()]` parameter definition and the end result will be a scriptblock containing the new interpreted function containing the full dynamic parameter definitions.

You can pipe the last command to `Set-ClipBoard` and paste it directly into your function script.

**Example:**

```powershell
# This function can be defined in a ps1 script and dot sourced into the session, e.g. . ./Get-Recipe.ps1

function Get-Recipe {
    param (
        [Parameter()]
        [switch]$Allergy,

        [Dynamic({$PSBoundParameters['Allergy']})]
        [Parameter(Mandatory)]
        [ValidateSet(
            'Nut',
            'Egg'
        )]
        [string]$AllergyType
    )

    process {
        if ($Allergy) {
            return "Here is a recipe that is $AllergyType free!"
        }

        return "Here is a delicious recipe!"
    }
}

Resolve-DynamicFunctionDefinition -FunctionInfo (Get-Command Get-Recipe)
```

**Result:**
```powershell
function Get-Recipe
{
    param
    (
        [Parameter(Mandatory)]
        [switch]$Allergy
    )

    dynamicparam
    {
        # create container for all dynamically created parameters:
        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        <#
            region Start Parameter -AllergyType ####
            created programmatically via Resolve-DynamicFunctionDefinition
        #>

        if ($PSBoundParameters['Allergy']) {
        # create container storing all attributes for parameter -AllergyType
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        # Define attribute [Parameter()]:
        $attrib = [Parameter]::new()
        $attrib.Mandatory=$true
        $attributeCollection.Add($attrib)

        # Define attribute [ValidateSet()]:
        $attrib = [ValidateSet]::new('Nut','Egg')
        $attributeCollection.Add($attrib)

        # compose dynamic parameter:
        $dynParam = [System.Management.Automation.RuntimeDefinedParameter]::new('AllergyType',[string],$attributeCollection)

        # add parameter to parameter collection:
        $paramDictionary.Add('AllergyType',$dynParam)
        }

        <#
            endregion End Parameter -AllergyType ####
            created programmatically via Resolve-DynamicFunctionDefinition
        #>

        # return dynamic parameter collection:
        $paramDictionary
    }

    begin {
        <#
            region initialize variables for dynamic parameters
            created programmatically via Resolve-DynamicFunctionDefinition
        #>

        if($PSBoundParameters.ContainsKey('AllergyType')) { $AllergyType = $PSBoundParameters['AllergyType'] }
        else { $AllergyType = $null}

        <#
            endregion initialize variables for dynamic parameters
            created programmatically via Resolve-DynamicFunctionDefinition
        #>
    }

    process {
        if ($Allergy) {
            return "Here is a $AllergyType free recipe!"
        }

        return "Here is a delicious recipe!"
    }
}

```

## Contributing

See our contribution docs [here](/CONTRIBUTING.md).

## 🙏 Acknowledgments

Inspired **greatly** by [Dr. Tobias Weltner](https://github.com/TobiasPSP/) and his amazing work at [powershell.one](https://powershell.one/)
