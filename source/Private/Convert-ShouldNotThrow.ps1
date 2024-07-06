<#
    .SYNOPSIS
        Converts a command `Should -Not -Throw` to the specified Pester syntax.

    .DESCRIPTION
        The Convert-ShouldBe function is used to convert a command `Should -Not -Throw` to
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
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Not -Throw')
        Convert-ShouldThrow -CommandAst $commandAst -Pester6

        This example converts the `Should -Not -Throw` command to Pester 6 syntax.

    .NOTES
        Pester 5 Syntax:
            Should -Throw [[-ActualValue] <Object>] [[-ExpectedMessage] <string>] [[-ErrorId] <string>] [[-ExceptionType] <type>] [[-Because] <string>] [-Not] [-PassThru]

            Positional parameters:
                Position 1: ExceptionMessage
                Position 2: ErrorId
                Position 3: ExceptionType
                Position 4: Because

        Pester 6 Syntax:
            There are no Should-* command to call in v6. In v6 the scriptblock
            should be called either directly or using the call operator, e.g:

            $null = & (<ActualValue>)

        Conversion notes:
            From Frode: "$null = & (<actualvalue>) should work for variables,
            script blocks and expressions (note parentheses). Running the code
            directly will send data to StandardOutput in the Test-object. Not a
            big deal unless there's a lot of output, but might as well assign it
            to null like -Throw."
#>
function Convert-ShouldNotThrow
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

        if ($isNegated)
        {
            <#
                Must extract the scriptblock from the CommandAst extent, the scriptblock
                is passed as the parameter ActualValue or passed thru the pipeline.
            #>
            $newExtentText = '& ({0})' -f (Get-ShouldThrowScriptBlock -CommandAst $CommandAst -ParameterName 'ActualValue' -ParsePipeline)
        }
        else
        {
            #$shouldNotThrowNotImplementedMessage = $script:localizedData.ShouldNotThrow_NotImplemented

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    'Convert-ShouldNotThrow should not be called without a negation parameter. Call Convert-ShouldThrow instead.', #$shouldNotThrowNotImplementedMessage,
                    'CSNT0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::NotImplemented,
                    $CommandAst.Extent.Text
                )
            )
        }
    }

    Write-Debug -Message ('Converted the command `{0}` to `{1}`.' -f $CommandAst.Extent.Text, $newExtentText)

    return $newExtentText
}
