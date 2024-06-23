<#
.SYNOPSIS
    Retrieves the Should command operator based on the provided CommandAst.

.DESCRIPTION
    The Get-ShouldCommandOperatorName function retrieves the Should command operator based
    on the provided CommandAst object. It searches for specific operators and their
    aliases in the CommandAst and returns the corresponding operator name.

.PARAMETER CommandAst
    Specifies the CommandAst object representing the command for which the Should
    operator needs to be retrieved.

.OUTPUTS
    System.String

    The Should command operator name.

.EXAMPLE
    $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Be "Hello"')
    Get-ShouldCommandOperatorName -CommandAst $commandAst

    Returns "Be"
#>

function Get-ShouldCommandOperatorName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.Language.CommandAst]
        $CommandAst
    )

    # Operators. Output from Pester's command Get-ShouldOperator.
    $possibleShouldOperator = @(
        'Be',
        'BeExactly',
        'BeGreaterThan',
        'BeLessOrEqual',
        'BeIn',
        'BeLessThan',
        'BeGreaterOrEqual',
        'BeLike',
        'BeLikeExactly',
        'BeNullOrEmpty',
        'BeOfType',
        'BeTrue',
        'BeFalse',
        'Contain',
        'Exist',
        'FileContentMatch',
        'FileContentMatchExactly',
        'FileContentMatchMultiline',
        'FileContentMatchMultilineExactly',
        'HaveCount',
        'HaveParameter',
        'Match',
        'MatchExactly',
        'Throw',
        'InvokeVerifiable',
        'Invoke'
    )

    # Operator aliases. Output from Pester's command Get-ShouldOperator.
    $possibleShouldOperator = @{
        'EQ' = 'Be'
        'CEQ' = 'BeExactly'
        'GT' = 'BeGreaterThan'
        'LE' = 'BeLessOrEqual'
        'LT' = 'BeLessThan'
        'GE' = 'BeGreaterOrEqual'
        'HaveType' = 'BeOfType'
        'CMATCH' = 'MatchExactly'
    }

    $shouldOperatorAsts = $Ast.Find({
        param($node)
        return $node -is [System.Management.Automation.Language.CommandParameterAst] -and ($node.ParameterName -in $possibleShouldOperator -or $node.ParameterName -in $possibleShouldOperatorAlias.Keys)
    }, $true)

    if ($shouldOperatorAsts.ParameterName -in $possibleShouldOperatorAlias.Keys)
    {
        return $possibleShouldOperatorAlias[$shouldOperatorAsts.ParameterName]
    }

    return $shouldOperatorAsts.ParameterName
}
