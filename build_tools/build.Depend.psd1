# DO NOT MODIFY!!
@{
    PSDependOptions       = @{
        Target    = '$DependencyFolder\_build_dependencies_\'
        AddToPath = $true
        Tags      = 'Build'
    }
    PSDepend              = '0.3.8'
    PSDeploy              = '1.0.5'
    BuildHelpers          = '2.0.15'
    Configuration         = '1.3.1'
    Plaster               = '1.1.3'
    PSObjectTools         = '0.1.0'
    InvokeBuild           = @{
        Version = '5.8.5'
        Tags    = 'Build'
    }
    Pester_5          = @{
        Name    = 'Pester'
        Version = '5.3.1'
        Tags    = 'Test'
        Target  = '$DependencyFolder\_build_dependencies_\Test\'
    }
}
