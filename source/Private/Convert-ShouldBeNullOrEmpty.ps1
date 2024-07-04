<#
    .SYNOPSIS
        Converts a command `Should -BeNullOrEmpty` to the specified Pester syntax.

    .DESCRIPTION
        The Convert-ShouldBeNullOrEmpty function is used to convert a command
        `Should -BeNullOrEmpty` to the specified Pester syntax.

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
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -BeNullOrEmpty')
        Convert-ShouldBeNullOrEmpty -CommandAst $commandAst -Pester6

        This example converts the `Should -BeNullOrEmpty` command to Pester 6 syntax.

    .NOTES
        Pester 5 Syntax:
            Should -BeNullOrEmpty [[-ActualValue] <Object>] [[-Because] <string>] [-Not]

            Positional parameters:
                Position 1: Because
                Position 2: ActualValue

        Pester 6 Syntax:
            Should-BeFalsy [[-Actual] <Object>] [[-Because] <String>]

            Positional parameters:
                Position 1: Actual
                Position 2: Because

        Conversion notes:
            If the Pester 5 syntax is negated it must be converted to Should-BeTruthy.

            If the Pester 5 syntax uses positional parameters, the conversion must
            convert position 1 to position 2 and vice versa.

            It should output informational message that the user should review the
            converted commands to evaluate if it should stay Should-BeFalsy or if
            Should-BeNull or Should-BeEmptyString should be used instead.
#>
function Convert-ShouldBeNullOrEmpty
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

    $sourceSyntaxVersion = Get-PesterCommandSyntaxVersion -CommandAst $CommandAst -CommandName 'Should' -ParameterName 'BeNullOrEmpty'

    # Parse the command elements and convert them to Pester 6 syntax
    if ($PSCmdlet.ParameterSetName -eq 'Pester6')
    {
        Write-Debug -Message ('Converting from Pester v{0} to Pester v6 syntax.' -f $sourceSyntaxVersion)

        # Add the correct Pester command based on negation
        if ($isNegated)
        {
            $newExtentText = 'Should-BeTruthy'
        }
        else
        {
            $newExtentText = 'Should-BeFalsy'
        }

        $getPesterCommandParameterParameters = @{
            CommandAst = $CommandAst
            CommandName = 'Should'
            IgnoreParameter = 'BeNullOrEmpty', 'Not'
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

        # This handles the named parameters in the command elements, added in alphabetical order.
        foreach ($currentParameter in $commandParameters.Keys | Sort-Object)
        {
            if ($commandParameters.$currentParameter.Positional -eq $true)
            {
                continue
            }

            switch ($currentParameter)
            {
                'ActualValue'
                {
                    $parameterName = 'Actual'

                    break
                }

                default
                {
                    $parameterName = $currentParameter

                    break
                }
            }

            $newExtentText += ' -{0} {1}' -f $parameterName, $commandParameters.$currentParameter.ExtentText
        }
    }

    Write-Debug -Message ('Converted the command `{0}` to `{1}`.' -f $CommandAst.Extent.Text, $newExtentText)

    return $newExtentText
}
