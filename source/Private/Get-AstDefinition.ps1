<#
    .SYNOPSIS
        Retrieves the ScriptBlockAst definition of a PowerShell script file.

    .DESCRIPTION
        The Get-AstDefinition function parses a PowerShell script file and retrieves
        the ScriptBlockAst definition. It uses the Parser.ParseFile method from the
        System.Management.Automation.Language namespace to parse the file.

    .PARAMETER Path
        Specifies the path to the PowerShell script file(s) to parse.
        This parameter supports pipeline input and accepts both strings and FileInfo
        objects.

    .OUTPUTS
        System.Management.Automation.Language.ScriptBlockAst

        The ScriptBlockAst definition of the parsed PowerShell script file.

    .EXAMPLE
        Get-AstDefinition -Path 'C:\Scripts\Script.ps1'

        Retrieves the ScriptBlockAst definition of the 'Script.ps1' file.

    .EXAMPLE
        'C:\Scripts\Script.ps1' | Get-AstDefinition

        Retrieves the ScriptBlockAst definition of the 'Script.ps1' file using
        pipeline input.

    .EXAMPLE
        Get-ChildItem -Path './scripts' | Get-AstDefinition

        Retrieves the ScriptBlockAst definition of all the files in the path pass
        as pipeline input.
#>
function Get-AstDefinition
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.ScriptBlockAst])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        [System.IO.FileInfo[]]
        $Path
    )

    process
    {
        foreach ($filePath in $Path)
        {
            $tokens, $parseErrors = $null

            Write-Verbose -Message "Parsing the script file: $filePath"

            [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref] $tokens, [ref] $parseErrors)

            if ($parseErrors)
            {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ($script:localizedData.FailedParseScriptAst -f $parseErrors[0].Message),
                        'GAD0001', # cSpell: disable-line
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $filePath
                    )
                )
            }
        }
    }
}
