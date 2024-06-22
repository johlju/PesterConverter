<#
    .SYNOPSIS
        Converts a command `Should -Be` to the specified Pester syntax.

    .DESCRIPTION
        The Switch-ShouldBe function is used to convert a command `Should -Be` to
        the specified Pester syntax. It takes a CommandAst object and a ToVersion
        parameter as input.

    .PARAMETER CommandAst
        The CommandAst object representing the command to be converted.

    .PARAMETER ToVersion
        The version of Pester to convert the command to. Only Pester version 6 is
        supported.

    .EXAMPLE
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Be "Test"')
        Switch-ShouldBe -commandAst $commandAst -ToVersion 6

        This example converts the `Should -Be "Test"` command to Pester 6 syntax.

    .NOTES
        Pester 5 Syntax:
            Should [[-ActualValue] <Object>] [-Be] [-Not] [-ExpectedValue <Object>] [-Because <Object>]

        Pester 6 Syntax:
            Should-Be [[-Actual] <Object>] [-Expected] <Object> [-Because <String>]
            Assert-Equal [[-Actual] <Object>] [-Expected] <Object> [-Because <String>]
            Should-NotBe [[-Actual] <Object>] [-Expected] <Object> [-Because <String>]
            Assert-NotEqual [[-Actual] <Object>] [-Expected] <Object> [-Because <String>]
#>

function Switch-ShouldBe
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.CommandAst]
        $CommandAst,

        [Parameter(Mandatory = $true, ParameterSetName = 'Pester6')]
        [System.Management.Automation.SwitchParameter]
        $Pester6,

        [Parameter(ParameterSetName = 'Pester6')]
        [System.Management.Automation.SwitchParameter]
        $NoCommandAlias,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UseNamedParameters
    )

    # Determine if the command is negated
    $negated = Test-PesterCommandNegated -CommandAst $commandAst

    # # Filter out the 'Not' parameter from the command elements
    # $commandParameterAst = @(
    #     $commandAst.CommandElements |
    #         Where-Object -FilterScript {
    #             (
    #                 $_ -is [System.Management.Automation.Language.CommandParameterAst] `
    #                 -or $_ -is [System.Management.Automation.Language.VariableExpressionAst]
    #             ) -and -not (
    #                 $_ -is [System.Management.Automation.Language.CommandParameterAst] `
    #                 -and $_.ParameterName -eq 'Not'
    #             )
    #         }
    # )

    # Parse the command elements and convert them to Pester 6 syntax
    if ($PSCmdlet.ParameterSetName -eq 'Pester6')
    {
        # Add the correct Pester command based on negation
        if ($negated)
        {
            if ($NoCommandAlias.IsPresent)
            {
                $newExtentText = 'Assert-NotEqual'
            }
            else
            {
                $newExtentText = 'Should-NotBe'
            }
        }
        else
        {
            if ($NoCommandAlias.IsPresent)
            {
                $newExtentText = 'Assert-Equal'
            }
            else
            {
                $newExtentText = 'Should-Be'
            }
        }

        foreach ($commandElement in $commandAst.CommandElements) #foreach ($element in $commandParameterAst)
        {
            if ($commandElement -is [System.Management.Automation.Language.CommandParameterAst])
            {
                $parameterName = $commandElement.ParameterName
                #$argument = $commandElement.Argument.Extent.Text

                # TODO: Handle to convert to positional parameters, which is the default
                # TODO: Handle to convert from positional parameters, or a combination of positional and named parameters
                switch ($parameterName)
                {
                    'ActualValue'
                    {
                        $newExtentText += " -Actual"

                        break
                    }

                    'ExpectedValue'
                    {
                        $newExtentText += " -Expected"

                        break
                    }

                    'Because'
                    {
                        $newExtentText += " -Because"

                        break
                    }

                    # 'Not'
                    # {
                    #     $newExtentText += " -Not:$argument"
                    #
                    #     break
                    # }
                }
            }
            elseif ($commandElement -is [System.Management.Automation.Language.VariableExpressionAst])
            {
                $newExtentText += " $($commandElement.Extent.Text)"
            }
        }
    }

    return $newExtentText
}
