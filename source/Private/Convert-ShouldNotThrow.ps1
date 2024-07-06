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
            There are no command to call, in v6 the scriptblock should be called
            using the call operator, e.g: $null = & (<actualvalue>)

        Conversion notes:
            From Frode: $null = & (<actualvalue>) should work for variables,
            script blocks and expressions (note parentheses). Running the code
            directly will send data to StandardOutput in the Test-object. Not a
            big deal unless there's a lot of output, but might as well assign it
            to null like -Throw.
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
            # TODO: This might need to be moved to a command Convert-ShouldNotThrow, and if Convert-ShouldThrow it should throw. Convert-PesterSyntax will need to check for negation as the parent AST need to be changed.
            # TODO: Must extract the scriptblock from the CommandAst extent, the scriptblock is passed as the parameter ActualValue or passed thru the pipeline.
            $newExtentText = Get-ShouldThrowScriptBlock -CommandAst $CommandAst -ParameterName 'ActualValue' -ParsePipeline
        }
        else
        {
            #$shouldThrowNotImplementedMessage = $script:localizedData.ShouldThrow_NotImplemented

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    'Convert-ShouldThrow should not be called with without negated command. Call Convert-ShouldThrow instead.', #$shouldThrowNotImplementedMessage,
                    'CST0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::NotImplemented,
                    $CommandAst.Extent.Text
                )
            )
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
        }

        $newExtentText += $commandParameters.ExceptionMessage.Positional ? (' {0}' -f $commandParameters.ExceptionMessage.ExtentText) : ''
        $newExtentText += $commandParameters.ErrorId.Positional ? (' {0}' -f $commandParameters.ErrorId.ExtentText) : ''
        $newExtentText += $commandParameters.ExceptionType.Positional ? (' {0}' -f $commandParameters.ExceptionType.ExtentText) : ''
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
                'ErrorId'
                {
                    $parameterNames += @{
                        FullyQualifiedErrorId = 'ErrorId'
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
