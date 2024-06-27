<#
    .SYNOPSIS
        Converts a command `Should -BeExactly` to the specified Pester syntax.

    .DESCRIPTION
        The Convert-ShouldBe function is used to convert a command `Should -BeExactly` to
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

    .PARAMETER UsePositionalParameters
        Specifies whether to use positional parameters in the converted syntax,
        where supported.

    .EXAMPLE
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -BeExactly "Test"')
        Convert-ShouldBeExactly -CommandAst $commandAst -Pester6 -NoCommandAlias

        This example converts the `Should -BeExactly "Test"` command to Pester 6 syntax
        without using command aliases.

    .NOTES
        Pester 5 Syntax:
            Should -BeExactly [-ActualValue <Object>] [-Not] [[-ExpectedValue] <Object>] [-Because <Object>]

        Pester 6 Syntax:
            Should-BeString [[-Actual] <Object>] [[-Expected] <String>] [-Because <String>] [-CaseSensitive] [-IgnoreWhitespace] - (Expected:Position 1, Actual:Position 2)
            Assert-StringEqual [[-Actual] <Object>] [[-Expected] <String>] [-Because <String>] [-CaseSensitive] [-IgnoreWhitespace] - (Expected:Position 1, Actual:Position 2)
            Should-NotBeString [[-Actual] <Object>] [[-Expected] <String>] [-Because <String>] [-CaseSensitive] [-IgnoreWhitespace] - (Expected:Position 1, Actual:Position 2)
            Assert-StringNotEqual [[-Actual] <Object>] [[-Expected] <String>] [-Because <String>] [-CaseSensitive] [-IgnoreWhitespace] - (Expected:Position 1, Actual:Position 2)
#>
function Convert-ShouldBeExactly
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
        $UseNamedParameters,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UsePositionalParameters
    )

    # Determine if the command is negated
    $isNegated = Test-PesterCommandNegated -CommandAst $CommandAst

    # TODO: Create a function Get-PesterCommandSyntaxVersion.
    if ($CommandAst.CommandElements[0].Extent.Text -eq 'Should' -and $CommandAst.CommandElements.ParameterName -contains 'BeExactly') {
        $sourceSyntaxVersion = 5
    }

    # Parse the command elements and convert them to Pester 6 syntax
    if ($PSCmdlet.ParameterSetName -eq 'Pester6')
    {
        Write-Verbose -Message ('Converting from Pester v{0} to Pester v6 syntax.' -f $sourceSyntaxVersion)

        # Add the correct Pester command based on negation
        if ($isNegated)
        {
            if ($NoCommandAlias.IsPresent)
            {
                $newExtentText = 'Assert-StringNotEqual'
            }
            else
            {
                $newExtentText = 'Should-NotBeString'
            }
        }
        else
        {
            if ($NoCommandAlias.IsPresent)
            {
                $newExtentText = 'Assert-StringEqual'
            }
            else
            {
                $newExtentText = 'Should-BeString'
            }
        }

        # Always add the `-CaseSensitive` parameter since BeExactly was case-sensitive.
        $newExtentText += ' -CaseSensitive'

        # TODO: Handle if the first element is positional

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
            next element in the command elements array is a variable expression or
            constant expression, assign the next elements value to a variable
            $positionalExpectedValue.

            Returns -1 if parameter 'BeExactly' is not found.
        #>
        $parameterIndex = $commandElement.IndexOf(
            (
                $commandElement |
                    Where-Object -FilterScript {
                        $_ -is [System.Management.Automation.Language.CommandParameterAst] `
                        -and $_.ParameterName -eq 'BeExactly'
                    }
            )
        )

        $positionalExpectedValue = $null
        $positionalValueElement = $null

        if ($parameterIndex -ne -1)
        {
            $nextElement = $commandElement[$parameterIndex + 1]

            if ($nextElement -is [System.Management.Automation.Language.ConstantExpressionAst] `
                -or $nextElement -is [System.Management.Automation.Language.VariableExpressionAst])
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
                    }
                }

                {
                    $_ -is [System.Management.Automation.Language.ConstantExpressionAst] `
                    -or $_ -is [System.Management.Automation.Language.VariableExpressionAst]
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
