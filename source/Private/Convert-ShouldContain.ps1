<#
    .SYNOPSIS
        Converts a command `Should -Contain` to the specified Pester syntax.

    .DESCRIPTION
        The Convert-ShouldContain function is used to convert a command `Should -Contain` to
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
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Contain "Test"')
        Convert-ShouldContain -CommandAst $commandAst -Pester6

        This example converts the `Should -Contain "Test"` command to Pester 6 syntax.

    .NOTES
        Pester 5 Syntax:
            Should -Contain [[-ActualValue] <Object>] [[-ExpectedValue] <Object>] [[-Because] <string>] [-Not]

            Positional parameters:
                Position 1: ExpectedValue
                Position 2: Because

        Pester 6 Syntax:
            Should-ContainCollection [-Actual] <Object>] [-Expected] <Object> [-Because <String>]
            Should-NotContainCollection [[-Actual] <Object>] [-Expected] <Object> [-Because <String>]

            Positional parameters:
                Position 1: Expected
                Position 2: Actual
#>
function Convert-ShouldContain
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

    $sourceSyntaxVersion = Get-PesterCommandSyntaxVersion -CommandAst $CommandAst

    # Parse the command elements and convert them to Pester 6 syntax
    if ($PSCmdlet.ParameterSetName -eq 'Pester6')
    {
        Write-Debug -Message ('Converting from Pester v{0} to Pester v6 syntax.' -f $sourceSyntaxVersion)

        # Add the correct Pester command based on negation
        if ($isNegated)
        {
            $newExtentText = 'Should-NotContainCollection'
        }
        else
        {
            $newExtentText = 'Should-ContainCollection'
        }

        $getPesterCommandParameterParameters = @{
            CommandAst = $CommandAst
            CommandName = 'Should'
            IgnoreParameter = @(
                'Contain'
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
            $commandParameters.Keys.ForEach({ $commandParameters.$_.Positional = $false })
        }
        elseif ($UsePositionalParameters.IsPresent)
        {
            # First set all to named parameters
            $commandParameters.Keys.ForEach({ $commandParameters.$_.Positional = $false })

            <#
                If a previous positional parameter is missing then the ones behind
                it cannot be set to positional.
            #>
            if ($commandParameters.ExpectedValue)
            {
                $commandParameters.ExpectedValue.Positional = $true

                if ($commandParameters.ActualValue)
                {
                    $commandParameters.ActualValue.Positional = $true
                }
            }
        }

        $newExtentText += $commandParameters.ExpectedValue.Positional ? (' {0}' -f $commandParameters.ExpectedValue.ExtentText) : ''
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

            $newExtentText += ' -{0} {1}' -f $currentParameter, $commandParameters.$originalParameterName.ExtentText
        }
    }

    Write-Debug -Message ('Converted the command `{0}` to `{1}`.' -f $CommandAst.Extent.Text, $newExtentText)

    return $newExtentText
}