<#
    .SYNOPSIS
        The localized resource strings in English (en-US). This file should only
        contain localized strings for private functions, public command, and
        classes (that are not a DSC resource).
#>

ConvertFrom-StringData @'
    # TODO: Fix the localization strings

    ## Get-AstDefinition
    FailedParseScriptAst = Failed to parse the script. Error: "{0}"

    ## Convert-PesterSyntax
    Convert_PesterSyntax_ShouldProcessVerboseDescription = Converting the script file '{0}'.
    Convert_PesterSyntax_ShouldProcessVerboseWarning = Are you sure you want to convert the script file '{0}'?
    # This string shall not end with full stop (.) since it is used as a title of ShouldProcess messages.
    Convert_PesterSyntax_ShouldProcessCaption = Convert script file
    Convert_PesterSyntax_StartPester6Conversion = Converting to Pester 6 syntax.
    Convert_PesterSyntax_NoVersionSpecified = No version syntax specified. Please specify a syntax version to convert to.
    Convert_PesterSyntax_WriteProgress_Id1_Activity = Converting to Pester 6 syntax.
    Convert_PesterSyntax_WriteProgress_Id1_Status_ProcessingFiles = Processing {0} file(s).
    Convert_PesterSyntax_WriteProgress_Id1_Status_ProcessingFile = Processing file '{0}'.
    Convert_PesterSyntax_WriteProgress_Id1_Status_Completed = Completed.
    Convert_PesterSyntax_WriteProgress_Id2_Activity = Converting Should command syntax.
    Convert_PesterSyntax_WriteProgress_Id2_Status_ProcessingCommands = Processing {0} command(s).
    Convert_PesterSyntax_WriteProgress_Id2_Status_ProcessingLine = Processing extent on line '{0}'.
    Convert_PesterSyntax_WriteProgress_Id2_Status_Completed = Completed.
    Convert_PesterSyntax_Debug_ScriptBlockAst = Parsing the script block AST: {0}
    Convert_PesterSyntax_Debug_FoundShouldCommand = Found {0} `Should` command(s) in file '{1}'.
    Convert_PesterSyntax_Warning_UnsupportedCommandOperator = Unsupported command operator '{0}' in extent: `{1}`
    Convert_PesterSyntax_MissingSupportedCommandOperator = Get-ShouldCommandOperatorName do not yet support the Should operator that was found in extent, or the operator name is short form instead of the full operator name: `{0}`
    Convert_PesterSyntax_NoPesterCommand = No supported Pester commands found in '{0}'.
    Convert_PesterSyntax_OutputPathDoesNotExist = The output path '{0}' does not exist. Please specify an existing path.
    Convert_PesterSyntax_OutputPathIsNotDirectory = The output path '{0}' is not a directory. Please specify a directory path.

    ## Common for all Convert-Should* functions
    Convert_Should_Debug_ParsingCommandAst = Parsing the command AST: `{0}`
    Convert_Should_Debug_ConvertingFromTo = Converting from Pester v{0} to Pester v{1} syntax.
    Convert_Should_Debug_ConvertedCommand = Converted the command `{0}` to `{1}`.

    ## Convert-AssertMockCalled
    Convert_AssertMockCalled_Debug_ParsingCommandAst = Parsing the command AST: `{0}`
    Convert_AssertMockCalled_Debug_ConvertingFromTo = Converting from Pester v{0} to Pester v{1} syntax.
    Convert_AssertMockCalled_Debug_ConvertedCommand = Converted the command `{0}` to `{1}`.
    Convert_AssertMockCalled_Debug_IntermediateStep = Converting Pester 4 syntax through Pester 5 as intermediate step.

    ## Convert-ShouldHaveCount
    Convert_HaveCount_Error_NegatedTestsNotSupported = Negated tests are not supported: '{0}'.

    ## Get-PesterCommandParameter
    Get_PesterCommandParameter_Debug_RetrievingParameters = Retrieving the parameters of the extent: {0}
    Get_PesterCommandParameter_Debug_RetrievingCommandName = Retrieving parameters for the command name: {0}
    Get_PesterCommandParameter_Debug_IgnoreParameters = Ignoring (filtering out) the parameters: {0}
    Get_PesterCommandParameter_Debug_NamedParameters = Parsing named parameters: {0}
    Get_PesterCommandParameter_Debug_PositionalParameters = Parsing positional parameters: {0}

    ## Get-CommandAst
    Get_CommandAst_Debug_RetrievingCommandAsts = Retrieving AST's for command '{0}'.

    ## ConvertTo-ActualParameterName
    AmbiguousNamedParameter = The named parameter '{0}' is ambiguous for command '{1}'. Please specify a unique named parameter.
    UnknownNamedParameter = The named parameter '{0}' is unknown for command '{1}'. Please specify a valid named parameter.
'@
