<#
    .SYNOPSIS
        Converts the syntax of a file to the syntax of a newer Pester version.

    .DESCRIPTION
        The Convert-PesterSyntax command is used to convert the syntax of a file to
        the syntax of a newer Pester version.. It supports converting to Pester 6 format.

    .PARAMETER Path
        Specifies the path of the file(s) to be converted. This parameter is mandatory
        and accepts a string or a FileInfo object.

    .PARAMETER Pester6
        Specifies that the syntax to convert to is Pester 6. This parameter is
        mandatory to convert to Pester 6 syntax.

    .PARAMETER UseNamedParameters
        Specifies whether to use named parameters in the converted syntax.

    .PARAMETER UsePositionalParameters
        Specifies whether to use positional parameters in the converted syntax,
        where supported.

    .EXAMPLE
        Convert-PesterSyntax -Path "C:\Scripts\Test.ps1" -Pester6

        Converts the syntax of the Test.ps1 file to Pester 6 syntax.

    .EXAMPLE
        Get-ChildItem -Path "C:\Scripts" -Recurse -Filter "*.ps1" | Convert-PesterSyntax

        Converts the syntax of all PowerShell files in the C:\Scripts directory and
        its subdirectories to the default (newest) Pester syntax.
#>

function Convert-PesterSyntax
{
    [CmdletBinding(DefaultParameterSetName = 'Pester6', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        [System.IO.FileInfo[]]
        $Path,

        [Parameter(ParameterSetName = 'Pester6')]
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

    begin
    {
        $assertBoundParameterParameters = @{
            BoundParameterList = $PSBoundParameters
            MutuallyExclusiveList1 = @('UseNamedParameters')
            MutuallyExclusiveList2 = @('UsePositionalParameters')
        }

        Assert-BoundParameter @assertBoundParameterParameters

        $convertParameters = @{} + $PSBoundParameters
        $convertParameters.Remove('Path')

        if ($PSCmdlet.ParameterSetName -eq 'Pester6' -and -not $Pester6.IsPresent)
        {
            $Pester6 = $true
            $convertParameters.Pester6 = $true
        }

        if ($Pester6)
        {
            Write-Verbose 'Converting to Pester 6 syntax.'
        }
        else
        {
            throw 'No version syntax specified. Please specify a format to convert to.'
        }
    }

    process
    {
        foreach ($filePath in $Path)
        {
            if ($filePath -is [System.String])
            {
                $filePath = Convert-Path -Path $filePath
            }

            $scriptBlockAst = $filePath | Get-AstDefinition -ErrorAction 'Stop'

            Write-Debug -Message ('Parsing the script block AST: {0}' -f $scriptBlockAst.Extent.Text)

            $shouldCommandAst = $scriptBlockAst | Get-CommandAst -CommandName 'Should' -ErrorAction 'Stop'

            if ($shouldCommandAst)
            {
                #$shouldCommandAst

                Write-Debug -Message ('Found {0} ''Should'' command(s) in {1}.' -f $shouldCommandAst.Count, $filePath)

                foreach ($commandAst in $shouldCommandAst)
                {
                    $operatorName = Get-ShouldCommandOperatorName -CommandAst $commandAst -ErrorAction 'Stop'

                    if ($operatorName)
                    {
                        switch ($operatorName)
                        {
                            'Be'
                            {
                                $newExtentText = Convert-ShouldBe -CommandAst $commandAst @convertParameters -ErrorAction 'Stop'
                            }

                            'BeExactly'
                            {
                                $newExtentText = Convert-ShouldBeExactly -CommandAst $commandAst @convertParameters -ErrorAction 'Stop'
                            }

                            'BeTrue'
                            {
                                $newExtentText = Convert-ShouldBeTrue -CommandAst $commandAst @convertParameters -ErrorAction 'Stop'
                            }

                            'BeFalse'
                            {
                                $newExtentText = Convert-ShouldBeFalse -CommandAst $commandAst @convertParameters -ErrorAction 'Stop'
                            }

                            'BeNullOrEmpty'
                            {
                                $newExtentText = Convert-ShouldBeNullOrEmpty -CommandAst $commandAst @convertParameters -ErrorAction 'Stop'
                            }

                            default
                            {
                                Write-Warning -Message ('Unsupported command operator ''{0}'' in extent `{1}`.' -f $operatorName, $commandAst.Extent.Text)
                            }
                        }

                        #$newExtentText
                    }

<#
                    # Replace the original extent text in $scriptBlockAst.Extent with the new extent text using the offsets of the commandAst.Extent

                    # Assuming $scriptBlockAst and $commandAst are already defined AST objects
                    # And $newExtentText contains the text you want to insert

                    # 1. Get start and end offsets of commandAst.Extent
                    $startOffset = $commandAst.Extent.StartOffset
                    $endOffset = $commandAst.Extent.EndOffset

                    # 2. Assuming $newExtentText is already defined

                    # 3. Get the entire script text
                    $scriptText = $scriptBlockAst.Extent.Text

                    # 4. Replace the portion of the script text
                    $modifiedScriptText = $scriptText.Remove($startOffset, $endOffset - $startOffset).Insert($startOffset, $newExtentText)

                    # 5. Optionally, re-parse the modified script text if needed
                    $modifiedScriptBlockAst = [System.Management.Automation.Language.Parser]::ParseInput($modifiedScriptText, [ref]$null, [ref]$null)

                    #$filePath | Set-FileContent -StartOffset $commandAst.Extent.StartOffset -EndOffset $commandAst.Extent.EndOffset -NewContent $newExtentText
#>


                    ### $commandAst.Extent:
                    # File                : /Users/johlju/source/PesterConverter/tests/MockScripts/ShouldBe.v5.mocktest.ps1
                    # StartScriptPosition : System.Management.Automation.Language.InternalScriptPosition
                    # EndScriptPosition   : System.Management.Automation.Language.InternalScriptPosition
                    # StartLineNumber     : 6
                    # StartColumnNumber   : 17
                    # EndLineNumber       : 6
                    # EndColumnNumber     : 33
                    # Text                : Should -Be $true
                    # StartOffset         : 189
                    # EndOffset           : 205

                    #$commandParameterAst

                    # $parameters = @()

                    # foreach ($parameter in $commandParameterAst)
                    # {
                    #     switch ($parameter)
                    #     {
                    #         { $_ -is [System.Management.Automation.Language.VariableExpressionAst] }
                    #         {
                    #             # Add the value to the previously added parameter.
                    #             $parameters[-1].ParameterValue = $parameter.Extent.Text
                    #         }

                    #         { $_ -is [System.Management.Automation.Language.CommandParameterAst] }
                    #         {
                    #             $newParameter = [PSCustomObject] @{
                    #                 ParameterName = $parameter.ParameterName
                    #                 ParameterValue = $null
                    #             }

                    #             $parameters += $newParameter
                    #         }

                    #         default
                    #         {
                    #             throw "Unknown parameter type $($_)."
                    #         }
                    #     }
                    # }

                    #$parameters

                    # $commandParameterAst = $commandAst.CommandElements[1]

                    # $syntaxConversion = @()

                    # switch ($commandParameterAst.ParameterName)
                    # {
                    #     <#
                    #         Pester 5 Syntax:
                    #         Should [[-ActualValue] <Object>] [-Be] [-Not] [-ExpectedValue <Object>] [-Because <Object>]
                    #     #>
                    #     'Be'
                    #     {
                    #         $syntaxConversion += [PSCustomObject] @{
                    #             OriginalExtent = $commandParameterAst.Parent.Extent.Text
                    #         }

                    #         # $shouldCommandAst.CommandElements[0].Value = 'Should'
                    #         # $shouldCommandAst.CommandElements[0].Extent.Text = 'Should'

                    #         # $shouldCommandAst.CommandElements[1].ParameterName = 'Be'
                    #         # $shouldCommandAst.CommandElements[1].Extent.Text = '-Be'

                    #         # $shouldCommandAst.CommandElements[2].Extent.Text = '$true'
                    #     }
                    # }
                }

                #$syntaxConversion
            }
            else
            {
                Write-Verbose -Message "No 'Should' command found in $filePath."
            }
        }
    }
}
