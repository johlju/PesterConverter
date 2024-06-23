<#
    .SYNOPSIS
        Converts a command `Should -Be` to the specified Pester syntax.

    .DESCRIPTION
        The Switch-ShouldBe function is used to convert a command `Should -Be` to
        the specified Pester syntax.

    .PARAMETER CommandAst
        The CommandAst object representing the command to be converted.

    .PARAMETER Pester6
        Specifies that the command should be converted to Pester version 6 syntax.

    .PARAMETER NoCommandAlias
        Specifies that the command should not use command aliases in the converted
        syntax. This parameter is only applicable when converting to Pester 6 syntax.

    .PARAMETER UseNamedParameters
        Specifies whether to use named parameters in the converted syntax.

    .EXAMPLE
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Be "Test"')
        Switch-ShouldBe -CommandAst $commandAst -Pester6 -NoCommandAlias

        This example converts the `Should -Be "Test"` command to Pester 6 syntax
        without using command aliases.

    .NOTES
        Pester 5 Syntax:
            Should [-ActualValue <Object>] [-Be] [-Not] [[-ExpectedValue] <Object>] [-Because <Object>]

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
    $isNegated = Test-PesterCommandNegated -CommandAst $CommandAst

    <#
        Returns true if the first command element is positional (is of type
        System.Management.Automation.Language.VariableExpressionAst)
    #>
    $firstElementIsPositional = Test-CommandElementIsPositional -CommandAst $CommandAst -FirstElement

    # # Filter out the 'Not' parameter from the command elements
    # $commandParameterAst = @(
    #     $CommandAst.CommandElements |
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
        Write-Verbose -Message 'Converting to Pester 6 syntax.'

        # Add the correct Pester command based on negation
        if ($isNegated)
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

        # TODO: Handle if the first element is positional

        $commandElement = $CommandAst.CommandElements |
            Where-Object -FilterScript {
                -not (
                    $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] `
                    -and $_.Extent.Text -eq 'Should'
                )
            }

        foreach ($currentCommandElement in $commandElement)
        {
            switch ($currentCommandElement)
            {
                {$_ -is [System.Management.Automation.Language.CommandParameterAst] }
                {
                    $parameterName = $currentCommandElement.ParameterName
                    #$argument = $currentCommandElement.Argument.Extent.Text

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

                {
                    $_ -is [System.Management.Automation.Language.ConstantExpressionAst] `
                    -or $_ -is [System.Management.Automation.Language.VariableExpressionAst]
                }
                {
                    $newExtentText += " $($currentCommandElement.Extent.Text)"
                }
            }
        }
    }

    Write-Verbose -Message "Converted command from $($CommandAst.Extent.Text) to $newExtentText."

    return $newExtentText
}
