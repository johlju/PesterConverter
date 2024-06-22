<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    ## Get-AstDefinition
    FailedParseScriptAst = Failed to parse the script. Error: "{0}"
'@
