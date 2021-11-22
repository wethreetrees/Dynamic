function Write-HelloStatic {
    [CmdletBinding()]
    param (
        [Parameter()]
        $Name = 'World'
    )

    process {
        Write-Output "Hello, $Name!"
    }

}