<#
    .SYNOPSIS
        Tests if the command element is positional.

    .DESCRIPTION
        The Test-CommandElementIsPositional function tests whether the command
        element is positional or not. It checks if the first element of the command
        is a variable expression.

    .PARAMETER CommandAst
        Specifies the CommandAst object representing the command.

    .PARAMETER FirstElement
        Specifies whether to check the first element or not.

    .OUTPUTS
        System.Boolean

        Returns $true if the first element is a positional element, otherwise returns $false.

    .EXAMPLE
        Test-CommandElementIsPositional -CommandAst $commandAst -FirstElement

        Tests if the first element of the command is positional.
#>
function Test-CommandElementIsPositional
{
    # TODO: This command might not be needed. It might have been done obsolete.
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.Language.CommandAst]
        $CommandAst,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $First
    )

    $result = $false

    if ($First.IsPresent)
    {
        $result = $commandAst.CommandElements[0] -is [System.Management.Automation.Language.VariableExpressionAst]
    }

    return $result
}
