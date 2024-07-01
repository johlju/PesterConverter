<#
    .SYNOPSIS
        Determines the Pester command syntax version based on the command and
        parameter name.

    .DESCRIPTION
        This function checks the command and parameter name used in a Pester command
        to determine the syntax version of the command. It supports identifying syntax
        versions based on specific commands and parameters.

    .PARAMETER CommandAst
        The abstract syntax tree of the command being analyzed.

    .PARAMETER CommandName
        The name of the command to check for in the AST. This allows for dynamic
        checking of different commands.

    .PARAMETER ParameterName
        The name of the parameter to check for in the command. This allows for
        dynamic checking of different parameters.

    .EXAMPLE
        $ast = [System.Management.Automation.Language.Parser]::ParseInput('Should -BeExactly "value"', [ref]$null, [ref]$null)
        Get-PesterCommandSyntaxVersion -CommandAst $ast -CommandName 'Should' -ParameterName 'BeExactly'

        Returns the syntax version for the 'Should -BeExactly' command.
#>
function Get-PesterCommandSyntaxVersion {
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]
        $CommandAst,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CommandName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ParameterName
    )

    $sourceSyntaxVersion = $null

    # Check if the first command element matches the CommandName and if any of the parameters match the ParameterName
    if ($CommandAst.CommandElements[0].Extent.Text -eq $CommandName -and $CommandAst.CommandElements.ParameterName -contains $ParameterName) {
        $sourceSyntaxVersion = 5
    }

    return $sourceSyntaxVersion
}
