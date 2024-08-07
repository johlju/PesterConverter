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

Describe 'Test-PesterCommandNegated' {
    It 'Should return the $†rue' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                Should -Not -Throw 'MockErrorMessage'
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Test-PesterCommandNegated -CommandAst $mockCommandAst

            $result | Should-BeTrue
        }
    }

    It 'Should return the $false' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                Should -Throw 'MockErrorMessage'
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Test-PesterCommandNegated -CommandAst $mockCommandAst

            $result | Should-BeFalse
        }
    }

    It 'Should return the $true when the command is part of a pipeline' {
        InModuleScope -ScriptBlock {
            $mockCommandAst = {
                Get-Something |
                    Get-ScriptBlock |
                        Should -Not -Throw 'MockErrorMessage'
            }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

            $result = Test-PesterCommandNegated -CommandAst $mockCommandAst

            $result | Should-BeTrue
        }
    }
}
