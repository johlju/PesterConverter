[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'PesterConverter'

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-ShouldThrowScriptBlock' {
    It 'Should return the correct script block from a parameter' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                Should -Not -Throw 'MockErrorMessage' -ActualValue {
                    Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
                }
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Get-ShouldThrowScriptBlock -CommandAst $mockCommandAst -ParameterName 'ActualValue' -ParsePipeline

            $result | Should-BeString -CaseSensitive "{
                    Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
                }"
        }
    }

    It 'Should return the correct extent text from a parameter when the a variable is used' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                $mockScriptBlock = {
                    Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
                }

                Should -Not -Throw 'MockErrorMessage' -ActualValue $mockScriptBlock
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Get-ShouldThrowScriptBlock -CommandAst $mockCommandAst -ParameterName 'ActualValue' -ParsePipeline

            $result | Should-BeString -CaseSensitive '$mockScriptBlock'
        }
    }

    It 'Should return the correct extent text from a pipeline' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                {
                    Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
                } | Should -Not -Throw 'MockErrorMessage'
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Get-ShouldThrowScriptBlock -CommandAst $mockCommandAst -ParameterName 'ActualValue' -ParsePipeline

            $result | Should-BeString -CaseSensitive "{
                    Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
                }"
        }
    }

    It 'Should return the correct extent text from a pipeline when the a variable is used' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                $mockScriptBlock = {
                    Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
                }

                $mockScriptBlock | Should -Not -Throw 'MockErrorMessage'
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Get-ShouldThrowScriptBlock -CommandAst $mockCommandAst -ParameterName 'ActualValue' -ParsePipeline

            $result | Should-BeString -CaseSensitive '$mockScriptBlock'
        }
    }

    It 'Should return the correct extent text from a pipeline when there are several pipeline elements' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                Get-Something | Get-ScriptBlock | Should -Not -Throw 'MockErrorMessage'
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Get-ShouldThrowScriptBlock -CommandAst $mockCommandAst -ParameterName 'ActualValue' -ParsePipeline

            $result | Should-BeString -CaseSensitive 'Get-Something | Get-ScriptBlock'
        }
    }

    It 'Should return the correct extent text from a pipeline when there are several pipeline elements on separate rows' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                Get-Something |
                    Get-ScriptBlock |
                        Should -Not -Throw 'MockErrorMessage'
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Get-ShouldThrowScriptBlock -CommandAst $mockCommandAst -ParameterName 'ActualValue' -ParsePipeline

            $result | Should-BeString -CaseSensitive 'Get-Something |
                    Get-ScriptBlock'
        }
    }

    It 'Should return $null when there is no pipeline input or parameter input' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                Should -Not -Throw
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Get-ShouldThrowScriptBlock -CommandAst $mockCommandAst -ParameterName 'ActualValue' -ParsePipeline

            $result | Should-BeNull
        }
    }
}
