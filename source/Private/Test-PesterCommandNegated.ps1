<#
    .SYNOPSIS
        Determines if a Pester command is negated.

    .DESCRIPTION
        The Test-PesterCommandNegated function is used to determine if a Pester
        command is negated. It searches for the 'Not' parameter in the CommandAst
        and also handles the scenario where the 'Not' parameter is specifically
        set to $false.

    .PARAMETER CommandAst
        The CommandAst object representing the Pester command.

    .EXAMPLE
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Not -Be "Test"')
        Test-PesterCommandNegated -CommandAst $commandAst

        Returns $true

    .EXAMPLE
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Be "Test"')
        Test-PesterCommandNegated -CommandAst $commandAst

        Returns $false

    .INPUTS
        System.Management.Automation.Language.CommandAst

    .OUTPUTS
        System.Boolean
#>
function Test-PesterCommandNegated
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]
        $CommandAst
    )

    $negateCommandParameterAst = $CommandAst.CommandElements |
        Where-Object -FilterScript {
            $_ -is [System.Management.Automation.Language.CommandParameterAst] `
            -and $_.ParameterName -eq 'Not' `
            -and $_.Argument.Extent.Text -ne '$false'
        }

    $negated = $false

    if ($negateCommandParameterAst)
    {
        $negated = $true
    }

    return $negated
}
