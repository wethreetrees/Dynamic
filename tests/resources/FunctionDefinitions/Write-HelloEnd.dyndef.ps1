function Write-HelloEnd {
    [CmdletBinding()]
    param (
        [Parameter()]
        $Name = 'World'
    )

    end {
        Write-Output "Hello, $Name!"
    }

}