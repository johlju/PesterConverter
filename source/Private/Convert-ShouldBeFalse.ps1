<#
    .SYNOPSIS
        Converts a command `Should -BeFalse` to the specified Pester syntax.

    .DESCRIPTION
        The Convert-ShouldBeFalse function is used to convert a command `Should -BeFalse` to
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
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -BeFalse')
        Convert-ShouldBeFalse -CommandAst $commandAst -Pester6

        This example converts the `Should -BeFalse` command to Pester 6 syntax.

    .NOTES
        Pester 5 Syntax:
            Should -BeFalse [[-ActualValue] <Object>] [[-Because] <Object>] [-Not]

            Positional parameters:
                Position 1: Because
                Position 2: ActualValue

        Pester 6 Syntax:
            Should-BeFalse [[-Actual] <Object>] [[-Because] <String>]

            Positional parameters:
                Position 1: Actual
                Position 2: Because

        Conversion notes:
            If the Pester 5 syntax is negated it must be converted to Should-BeTrue.
#>
function Convert-ShouldBeFalse
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

    $sourceSyntaxVersion = Get-PesterCommandSyntaxVersion -CommandAst $CommandAst -CommandName 'Should' -ParameterName 'BeFalse'

    # Parse the command elements and convert them to Pester 6 syntax
    if ($PSCmdlet.ParameterSetName -eq 'Pester6')
    {
        Write-Debug -Message ('Converting from Pester v{0} to Pester v6 syntax.' -f $sourceSyntaxVersion)

        # Add the correct Pester command based on negation
        if ($isNegated)
        {
            $newExtentText = 'Should-BeTrue'
        }
        else
        {
            $newExtentText = 'Should-BeFalse'
        }

        $getPesterCommandParameterParameters = @{
            CommandAst = $CommandAst
            CommandName = 'Should'
            IgnoreParameter = 'BeFalse', 'Not'
            PositionalParameter = 'Because', 'ActualValue'
        }

        $commandParameters = Get-PesterCommandParameter @getPesterCommandParameterParameters

        # Determine if named or positional parameters should be forcibly used
        if ($UseNamedParameters.IsPresent)
        {
            if ($commandParameters.ActualValue)
            {
                $commandParameters.ActualValue.Positional = $false
            }

            if ($commandParameters.Because)
            {
                $commandParameters.Because.Positional = $false
            }
        }
        elseif ($UsePositionalParameters.IsPresent)
        {
            if ($commandParameters.ActualValue)
            {
                $commandParameters.ActualValue.Positional = $true
            }

            if ($commandParameters.Because)
            {
                $commandParameters.Because.Positional = $true
            }
        }

        $newExtentText += $commandParameters.ActualValue.Positional ? (' {0}' -f $commandParameters.ActualValue.ExtentText) : ''
        $newExtentText += $commandParameters.Because.Positional ? (' {0}' -f $commandParameters.Because.ExtentText) : ''

        # Holds the the new parameter names so they can be added in alphabetical order.
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
