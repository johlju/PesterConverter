<#
    .SYNOPSIS
        Converts a command `Should -BeOfType` to the specified Pester syntax.

    .DESCRIPTION
        The Convert-ShouldBe function is used to convert a command `Should -BeOfType`
        to the specified Pester syntax.

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
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -BeOfType [System.String]')
        Convert-ShouldBeOfType -CommandAst $commandAst -Pester6

        This example converts the `Should -BeOfType [System.String]` command to Pester 6 syntax.

    .NOTES
        Pester 5 Syntax:
            Should -BeOfType [[-ActualValue] <Object>] [[-ExpectedType] <Object>] [[-Because] <string>] [-Not]

            Positional parameters:
                Position 1: ExpectedValue
                Position 2: Because

        Pester 6 Syntax:
            Should-HaveType [[-Actual] <Object>] [-Expected] <Type> [-Because <String>]
            Should-NotBe [[-Actual] <Object>] [-Expected] <Object> [-Because <String>]

            Positional parameters:
                Position 1: Expected
                Position 2: Actual

        Conversion notes:
            The expected value should be surrounded by parenthesis after conversion
            in v6, e.g. `[System.String]` -> `([System.String])`.

            The `-ActualValue` parameter is only supported as a named parameter in
            v5 even if syntax says otherwise. If ActualValue is used it will concatenate
            with the Because value and wrongly always return an array. Did not find
            a way to prevent that.

            The `-Not` parameter is not supported in v6. It should be changed to the
            command `Should-NotHaveType`.

            The `-Because` parameter is only supported as a named parameter in v6.
#>
function Convert-ShouldBeOfType
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

    $assertBoundParameterParameters = @{
        BoundParameterList = $PSBoundParameters
        MutuallyExclusiveList1 = @('UseNamedParameters')
        MutuallyExclusiveList2 = @('UsePositionalParameters')
    }

    Assert-BoundParameter @assertBoundParameterParameters

    Write-Debug -Message ('Parsing the command AST: {0}' -f $CommandAst.Extent.Text)

    # Determine if the command is negated
    $isNegated = Test-PesterCommandNegated -CommandAst $CommandAst

    $sourceSyntaxVersion = Get-PesterCommandSyntaxVersion -CommandAst $CommandAst -CommandName 'Should' -ParameterName 'BeOfType'

    # Parse the command elements and convert them to Pester 6 syntax
    if ($PSCmdlet.ParameterSetName -eq 'Pester6')
    {
        Write-Debug -Message ('Converting from Pester v{0} to Pester v6 syntax.' -f $sourceSyntaxVersion)

        # Add the correct Pester command based on negation
        if ($isNegated)
        {
            $newExtentText = 'Should-NotHaveType'
        }
        else
        {
            $newExtentText = 'Should-HaveType'
        }

        $getPesterCommandParameterParameters = @{
            CommandAst = $CommandAst
            CommandName = 'Should'
            IgnoreParameter = @(
                'BeOfType'
                'HaveType'
                'Not'
            )
            PositionalParameter = @(
                'ExpectedValue'
                'Because'
            )
            NamedParameter = @(
                'ActualValue'
            )
        }

        $commandParameters = Get-PesterCommandParameter @getPesterCommandParameterParameters

        # Parameter 'Because' is only supported as named parameter in Pester 6 syntax.
        if ($commandParameters.Because)
        {
            $commandParameters.Because.Positional = $false
        }

        # Determine if named or positional parameters should be forcibly used
        if ($UseNamedParameters.IsPresent)
        {
            if ($commandParameters.ExpectedValue)
            {
                $commandParameters.ExpectedValue.Positional = $false
            }

            if ($commandParameters.ActualValue)
            {
                $commandParameters.ActualValue.Positional = $false
            }
        }
        elseif ($UsePositionalParameters.IsPresent)
        {
            if ($commandParameters.ExpectedValue)
            {
                $commandParameters.ExpectedValue.Positional = $true
            }

            if ($commandParameters.ActualValue)
            {
                $commandParameters.ActualValue.Positional = $true
            }
        }

        # '[System.String]' -match '^\[.+\]$'
        if ($commandParameters.ExpectedValue.Positional)
        {
            # Add the expected value in parenthesis only if the extent text is a type defined in square brackets.
            $extentTextFormat = $commandParameters.ExpectedValue.ExtentText -match '^\[.+\]$' ? ' ({0})' : ' {0}'
            $newExtentText += $extentTextFormat -f $commandParameters.ExpectedValue.ExtentText
        }

        $newExtentText += $commandParameters.ActualValue.Positional ? (' {0}' -f $commandParameters.ActualValue.ExtentText) : ''

        # Holds the new parameter names so they can be added in alphabetical order.
        $parameterNames = @()

        foreach ($currentParameter in $commandParameters.Keys)
        {
            if ($commandParameters.$currentParameter.Positional -eq $true)
            {
                continue
            }

            switch ($currentParameter)
            {
                'ActualValue'
                {
                    $parameterNames += @{
                        Actual = 'ActualValue'
                    }

                    break
                }

                'ExpectedValue'
                {
                    $parameterNames += @{
                        Expected = 'ExpectedValue'
                    }

                    break
                }

                default
                {
                    $parameterNames += @{
                        $currentParameter = $currentParameter
                    }

                    break
                }
            }
        }

        # This handles the named parameters in the command elements, added in alphabetical order.
        foreach ($currentParameter in $parameterNames.Keys | Sort-Object)
        {
            $originalParameterName = $parameterNames.$currentParameter

            # Add the expected value in parenthesis only if the extent text is a type defined in square brackets.
            $extentTextFormat = $originalParameterName -eq 'ExpectedValue' -and $commandParameters.$originalParameterName.ExtentText -match '^\[.+\]$' ? '({1})' : '{1}'

            $newExtentText += " -{0} $extentTextFormat" -f $currentParameter, $commandParameters.$originalParameterName.ExtentText
        }
    }

    Write-Debug -Message ('Converted the command `{0}` to `{1}`.' -f $CommandAst.Extent.Text, $newExtentText)

    return $newExtentText
}
