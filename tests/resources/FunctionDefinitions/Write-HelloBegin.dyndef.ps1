function Write-HelloBegin {
    [CmdletBinding()]
    param (
        [Parameter()]
        $Name = 'World'
    )

    begin {
        Write-Output "Hello, $Name!"
    }

}