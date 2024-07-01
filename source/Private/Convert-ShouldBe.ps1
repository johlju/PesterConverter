<#
    .SYNOPSIS
        Converts a command `Should -Be` to the specified Pester syntax.

    .DESCRIPTION
        The Convert-ShouldBe function is used to convert a command `Should -Be` to
        the specified Pester syntax.

    .PARAMETER CommandAst
        The CommandAst object representing the command to be converted.

    .PARAMETER Pester6
        Specifies that the command should be converted to Pester version 6 syntax.

    .PARAMETER UseNamedParameters
        Specifies whether to use named parameters in the converted syntax.

    .PARAMETER UsePositionalParameters
        Specifies whether to use positional parameters in the converted syntax,
        where supported.

    .EXAMPLE
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Be "Test"')
        Convert-ShouldBe -CommandAst $commandAst -Pester6 -NoCommandAlias

        This example converts the `Should -Be "Test"` command to Pester 6 syntax
        without using command aliases.

    .NOTES
        Pester 5 Syntax:
            Should -Be [-ActualValue <Object>] [-Not] [[-ExpectedValue] <Object>] [-Because <Object>]

            Positional parameters:
                Position 1: ExceptedValue
                Position 2: Because
                Position 2: ActualValue

        Pester 6 Syntax:
            Should-Be [[-Actual] <Object>] [-Expected] <Object> [-Because <String>]
            Should-NotBe [[-Actual] <Object>] [-Expected] <Object> [-Because <String>]

            Positional parameters:
                Position 1: Expected
                Position 2: Actual
#>
function Convert-ShouldBe
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

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UseNamedParameters,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UsePositionalParameters
    )

    Write-Debug -Message ('Parsing the command AST: {0}' -f $CommandAst.Extent.Text)

    # Determine if the command is negated
    $isNegated = Test-PesterCommandNegated -CommandAst $CommandAst

    $sourceSyntaxVersion = Get-PesterCommandSyntaxVersion -CommandAst $CommandAst -CommandName 'Should' -ParameterName 'Be'

    # Parse the command elements and convert them to Pester 6 syntax
    if ($PSCmdlet.ParameterSetName -eq 'Pester6')
    {
        Write-Debug -Message ('Converting from Pester v{0} to Pester v6 syntax.' -f $sourceSyntaxVersion)

        # Add the correct Pester command based on negation
        if ($isNegated)
        {
            $newExtentText = 'Should-NotBe'
        }
        else
        {
            $newExtentText = 'Should-Be'
        }

        $commandElement = $CommandAst.CommandElements |
            Where-Object -FilterScript {
                -not (
                    $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] `
                    -and $_.Extent.Text -eq 'Should'
                )
            }

        <#
            Returns true if the first command element is positional (is of type
            System.Management.Automation.Language.VariableExpressionAst)
        #>
        #$firstElementIsPositional = Test-CommandElementIsPositional -CommandAst $CommandAst -First

        # TODO: Can the code below be turned into a function, maybe refactor the used one above?

        <#
            Search for the parameter name "Be" in the command elements and if the
            next element in the command elements array is a variable expression,
            constant expression or ParenExpressionAst, assign the next elements
            value to a variable $positionalExpectedValue.

            Returns -1 if parameter 'Be' is not found.
        #>
        $parameterIndex = $commandElement.IndexOf(
            (
                $commandElement |
                    Where-Object -FilterScript {
                        $_ -is [System.Management.Automation.Language.CommandParameterAst] `
                        -and $_.ParameterName -eq 'Be'
                    }
            )
        )

        $positionalExpectedValue = $null
        $positionalValueElement = $null

        if ($parameterIndex -ne -1)
        {
            $nextElement = $commandElement[$parameterIndex + 1]

            if ($nextElement -is [System.Management.Automation.Language.ConstantExpressionAst] `
                -or $nextElement -is [System.Management.Automation.Language.VariableExpressionAst] `
                -or $nextElement -is [System.Management.Automation.Language.ParenExpressionAst])
            {
                $positionalExpectedValue = $nextElement.Extent.Text
                $positionalValueElement = $nextElement
            }
        }

        if ($positionalExpectedValue)
        {
            if ($UsePositionalParameters.IsPresent)
            {
                # Force usage of positional parameters.
                $newExtentText += " $positionalExpectedValue"
            }
            elseif ($UseNamedParameters.IsPresent)
            {
                # Force usage of named parameters.
                $newExtentText += " -Expected $positionalExpectedValue"
            }
            else
            {
                # Default is to do it as it was coded before.
                $newExtentText += " $positionalExpectedValue"
            }
        }

        foreach ($currentCommandElement in $commandElement)
        {
            # Skip the element if it is the one that was used as the positional parameter.
            if ($positionalValueElement -and $currentCommandElement.Equals($positionalValueElement))
            {
                continue
            }

            switch ($currentCommandElement)
            {
                {$_ -is [System.Management.Automation.Language.CommandParameterAst] }
                {
                    $parameterName = $currentCommandElement.ParameterName
                    #$argument = $currentCommandElement.Argument.Extent.Text

                    # Parameters to be ignored.
                    if ($parameterName -in @('Be', 'Not'))
                    {
                        continue
                    }

                    switch ($parameterName)
                    {
                        'ActualValue'
                        {
                            # If positional parameters were requested, the parameter name should be ignored.
                            if (-not $UsePositionalParameters.IsPresent)
                            {
                                $newExtentText += ' -Actual'
                            }

                            break
                        }

                        'ExpectedValue'
                        {
                            $newExtentText += ' -Expected'

                            break
                        }

                        'Because'
                        {
                            $newExtentText += ' -Because'

                            break
                        }

                        # 'Not'
                        # {
                        #     $newExtentText += " -Not:$argument"
                        #
                        #     break
                        # }

                        default
                        {
                            Write-Warning -Message "Unsupported command parameter '$parameterName' in extent '$($currentCommandElement.Extent.Text)'"
                        }
                    }
                }

                {
                    $_ -is [System.Management.Automation.Language.ConstantExpressionAst] `
                    -or $_ -is [System.Management.Automation.Language.VariableExpressionAst] `
                    -or $_ -is [System.Management.Automation.Language.ParenExpressionAst]
                }
                {

                    $newExtentText += " $($currentCommandElement.Extent.Text)"
                }

                default
                {
                    Write-Warning -Message "Unsupported command element type: $($currentCommandElement.GetType().Name)"
                }
            }
        }
    }

    Write-Debug -Message ('Converted the command `{0}` to `{1}`.' -f $CommandAst.Extent.Text, $newExtentText)

    return $newExtentText
}
