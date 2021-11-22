function Write-Hi {
    param (
        $Name = 'World'
    )

    process {
        Write-Output "Hi, $Name!"
    }

}