function Get-DynamicFunctionParameterCommentHelp {
    [CmdletBinding()]
    param (
        # ParameterAst object
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ParameterAst]$ParameterAst,

        # FunctionInfo object
        [Parameter(Mandatory)]
        [System.Management.Automation.FunctionInfo]$FunctionInfo
    )

    process {
        New-Variable tokens -Force
        New-Variable err -Force

        $null = [System.Management.Automation.Language.Parser]::ParseInput($FunctionInfo.Definition, [ref]$tokens, [ref]$err)

        $comments = $tokens | Where-Object { $_.Kind -eq 'comment' }
        $scriptBlockStartLine = $FunctionInfo.ScriptBlock.ast.Body.Extent.StartLineNumber

        $comment = $comments | Where-Object {
            $ParameterAst.Extent.StartLineNumber - $scriptBlockStartLine -eq $_.Extent.StartLineNumber
        }
        if ($comment) {
            $comment.Text
        }
    }

}
