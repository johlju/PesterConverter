<#
    .SYNOPSIS
        Converts a command `Should -Throw` to the specified Pester syntax.

    .DESCRIPTION
        The Convert-ShouldBe function is used to convert a command `Should -Throw` to
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
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Throw "Test"')
        Convert-ShouldThrow -CommandAst $commandAst -Pester6

        This example converts the `Should -Throw "Test"` command to Pester 6 syntax.

    .NOTES
        Pester 5 Syntax:
            Should -Throw [[-ActualValue] <Object>] [[-ExpectedMessage] <string>] [[-ErrorId] <string>] [[-ExceptionType] <type>] [[-Because] <string>] [-Not] [-PassThru]

            Positional parameters:
                Position 1: ExceptionMessage
                Position 2: ErrorId
                Position 3: ExceptionType
                Position 4: Because

        Pester 6 Syntax:
            Should-Throw [-ScriptBlock] <ScriptBlock> [[-ExceptionType] <Type>] [[-ExceptionMessage] <String>] [[-FullyQualifiedErrorId] <String>] [-AllowNonTerminatingError] [[-Because] <String>]

            Positional parameters:
                Position 1: ScriptBlock
                Position 2: ExceptionType
                Position 3: ExceptionMessage
                Position 4: FullyQualifiedErrorId
                Position 5: Because

        Conversion notes:
            If the Pester 5 syntax does not have ActualValue as named parameter
            then it is not possible to use positional parameters, if there is
            pipeline input then it is not possible to convert to positional parameters.

            Pester 5 syntax Pos 1 must be converted to Pos 3 in Pester 6 syntax
            Pester 5 syntax Pos 2 must be converted to Pos 4 in Pester 6 syntax
            Pester 5 syntax Pos 3 must be converted to Pos 2 in Pester 6 syntax
            Pester 5 syntax Pos 4 must be converted to Pos 5 in Pester 6 syntax

            PassThru is the default in Pester 6, so it can be ignored in the conversion.
            But must be handled if it can have negative impact were it was not used
            before.

            TODO: The positional parameters in v6 are not in the same order as in v5.
            The code below assume they will be the same in a future v6 alpha. If not
            the code below need to be change to force named parameters.
#>
function Convert-ShouldThrow
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

    $sourceSyntaxVersion = Get-PesterCommandSyntaxVersion -CommandAst $CommandAst -CommandName 'Should' -ParameterName 'Throw'

    # Parse the command elements and convert them to Pester 6 syntax
    if ($PSCmdlet.ParameterSetName -eq 'Pester6')
    {
        Write-Debug -Message ('Converting from Pester v{0} to Pester v6 syntax.' -f $sourceSyntaxVersion)

        # Add the correct Pester command based on negation
        if ($isNegated)
        {
            #$shouldThrowNotImplementedMessage = $script:localizedData.ShouldThrow_NotImplemented

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    'Convert-ShouldThrow should not be called with a negation parameter. Call Convert-ShouldNotThrow instead.', #$shouldThrowNotImplementedMessage,
                    'CST0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::NotImplemented,
                    $CommandAst.Extent.Text
                )
            )
        }
        else
        {
            $newExtentText = 'Should-Throw'
        }

        $getPesterCommandParameterParameters = @{
            CommandAst = $CommandAst
            CommandName = 'Should'
            IgnoreParameter = @(
                'Throw'
                'Not'
                'PassThru'
            )
            PositionalParameter = @(
                'ExceptionMessage'
                'ErrorId'
                'ExceptionType'
                'Because'
            )
            NamedParameter = @(
                'ActualValue'
            )
        }

        $commandParameters = Get-PesterCommandParameter @getPesterCommandParameterParameters

        # TODO: Remove this unless some parameters must be forcibly to named parameters.
        # # Parameter 'Because' is only supported as named parameter in Pester 6 syntax.
        # if ($commandParameters.Because)
        # {
        #     $commandParameters.Because.Positional = $false
        # }

        # # Determine if named or positional parameters should be forcibly used
        if ($UseNamedParameters.IsPresent)
        {
            if ($commandParameters.ExceptionMessage)
            {
                $commandParameters.ExceptionMessage.Positional = $false
            }

            if ($commandParameters.ErrorId)
            {
                $commandParameters.ErrorId.Positional = $false
            }

            if ($commandParameters.ExceptionType)
            {
                $commandParameters.ExceptionType.Positional = $false
            }

            if ($commandParameters.Because)
            {
                $commandParameters.Because.Positional = $false
            }
        }
        elseif ($UsePositionalParameters.IsPresent)
        {
            if ($commandParameters.ExceptionMessage)
            {
                $commandParameters.ExceptionMessage.Positional = $true
            }

            if ($commandParameters.ErrorId)
            {
                $commandParameters.ErrorId.Positional = $true
            }

            if ($commandParameters.ExceptionType)
            {
                $commandParameters.ExceptionType.Positional = $true
            }

            if ($commandParameters.Because)
            {
                $commandParameters.Because.Positional = $true
            }

            if ($commandParameters.ActualValue)
            {
                $commandParameters.ActualValue.Positional = $true
            }
        }

        $newExtentText += $commandParameters.ExceptionMessage.Positional ? (' {0}' -f $commandParameters.ExceptionMessage.ExtentText) : ''
        $newExtentText += $commandParameters.ErrorId.Positional ? (' {0}' -f $commandParameters.ErrorId.ExtentText) : ''
        $newExtentText += $commandParameters.ExceptionType.Positional ? (' {0}' -f $commandParameters.ExceptionType.ExtentText) : ''
        $newExtentText += $commandParameters.Because.Positional ? (' {0}' -f $commandParameters.Because.ExtentText) : ''
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
                'ErrorId'
                {
                    $parameterNames += @{
                        FullyQualifiedErrorId = 'ErrorId'
                    }

                    break
                }

                'ActualValue'
                {
                    $parameterNames += @{
                        ScriptBlock = 'ActualValue'
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
