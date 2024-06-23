# TODO: Add comment-based help
function Get-CommandAst
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.CommandAst[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.Language.Ast]
        $Ast,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CommandName
    )

    $shouldAsts = $Ast.FindAll({
        param($node)
        return $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq $CommandName
    }, $true)

    return $shouldAsts
}
