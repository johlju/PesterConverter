<#
    .SYNOPSIS
        Get the extent text of all the positional parameters of a Pester command.

    .DESCRIPTION
        The Get-PesterCommandParameter function returns all of the extent
        texts of the command elements that are positional. THe positional parameters
        are returned in the order they are written in the passed CommandAst.

    .PARAMETER CommandAst
        Specifies the CommandAst object representing the command.

    .PARAMETER CommandName
        Specifies the name of the command.

    .PARAMETER IgnoreParameter
        Specifies all the parameters that should be ignored.

    .PARAMETER NamedParameter
        Specifies all the names of the parameters that are not positional, and
        have a value associated with them.

    .PARAMETER PositionalParameter
        Specifies all the names of the positional parameters that can have values
        associated with them. Must be in the order of their numeric position.

    .OUTPUTS
        System.String[]

        Returns an array of all the extent texts of the positional parameters.

    .EXAMPLE
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should -Be "Test"')
        Get-PesterCommandParameter -CommandAst $commandAst -IgnoreParameter 'Be', 'Not' -PositionalParameter 'ActualValue', 'ExpectedValue', 'Because'

        Returns `$null`.

    .EXAMPLE
        $commandAst = [System.Management.Automation.Language.Parser]::ParseInput('Should "ExpectedString" "mock should test correct value" "ActualString" -Be')
        Get-PesterCommandParameter -CommandAst $commandAst -IgnoreParameter 'Be', 'Not' -PositionalParameter 'ActualValue', 'ExpectedValue', 'Because'

        Returns an array with the extent text of the positional parameters in the correct order.
#>
function Get-PesterCommandParameter
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.Language.CommandAst]
        $CommandAst,

        [Parameter(Mandatory = $true)]
        [System.String]
        $CommandName,

        [Parameter()]
        [System.String[]]
        $IgnoreParameter = @(),

        [Parameter()]
        [System.String[]]
        $NamedParameter = @(),

        [Parameter()]
        [System.String[]]
        $PositionalParameter = @()
    )

    # Filter out the command name from the command elements.
    $commandElement = $CommandAst.CommandElements |
            Where-Object -FilterScript {
                -not (
                    $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] `
                    -and $_.Extent.Text -eq $CommandName
                )
            }

    <#
        Filter out the parameters to ignore from the command elements, e.g.:
            - Be
            - Not
    #>
    $commandElement = $commandElement |
        Where-Object -FilterScript {
            -not (
                $_ -is [System.Management.Automation.Language.CommandParameterAst] `
                -and $_.ParameterName -in $IgnoreParameter
            )
        }

    # Build a hashtable based on the values in $PositionalParameter
    $positionalParameterHashtable = @{}

    if ($commandElement.Count -gt 0)
    {
        <#
            Filter out the value parameters including its values from the command elements, e.g.:
                - ActualValue
                - ExpectedValue
                - Because
        #>
        $parameterElements = $commandElement.Where({$_ -is [System.Management.Automation.Language.CommandParameterAst] -and ($_.ParameterName -in $PositionalParameter -or $_.ParameterName -in $NamedParameter)})

        $filterCommandElements = @()

        foreach ($parameterElement in $parameterElements)
        {
            $parameterIndex = $commandElement.IndexOf($parameterElement)

            # Above returned -1 if parameter name was not found.
            if ($parameterIndex -ne -1)
            {
                $parameterName = $commandElement[$parameterIndex].ParameterName

                $positionalParameterHashtable.$parameterName = @{
                    Position = 0
                    Positional = $false
                    ExtentText = $commandElement[$parameterIndex + 1].Extent.Text
                }

                $filterCommandElements += $commandElement[$parameterIndex]
                $filterCommandElements += $commandElement[$parameterIndex + 1]
            }
        }

        # Filter out the value parameter and its value from the command elements.
        $commandElement = $commandElement |
            Where-Object -FilterScript { $_ -notin $filterCommandElements }
    }

    # Get the positional parameters extent text that are left (if any).
    if ($commandElement.Count -gt 0)
    {
        $elementCounter = 0
        $positionalCounter = 1

        foreach ($parameter in $PositionalParameter)
        {
            # Only add the positional parameter if it does not exist in the hashtable.
            if (-not $positionalParameterHashtable.ContainsKey($parameter))
            {
                # Only add positional parameter if there actually a value for it.
                $positionalParameterHashtable.$parameter = @{
                    Position = $positionalCounter
                    Positional = $true
                    ExtentText = $commandElement[$elementCounter].Extent.Text #? $commandElement.Extent.Text : $null
                }

                # Increment the positional counter.
                $elementCounter++

                # If the command element is $null then there are no more positional parameters to process.
                if ($null -eq $commandElement[$elementCounter])
                {
                    break
                }
            }

            # Increment the positional counter.
            $positionalCounter++
        }
    }

    return $positionalParameterHashtable
}
