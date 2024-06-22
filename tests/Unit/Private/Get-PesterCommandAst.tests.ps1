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

Describe 'Get-PesterCommandAst' {
    It 'Should return the correct CommandAst for Should -Be $true' {
        InModuleScope -ScriptBlock {
            $mockAst = {
                Describe 'ShouldBe' [
                    It 'Should be true' {
                        $true | Should -Be $true
                    }
            }.Ast

            $result = Get-PesterCommandAst -Ast $mockAst -CommandName 'Should'

            $result | Should-HaveType ([System.Management.Automation.Language.CommandAst])
            $result.CommandElements[0].Value | Should-Be 'Should'
            $result.CommandElements[0].Extent.Text | Should-Be 'Should'

            $result.CommandElements[1].ParameterName | Should-Be 'Be'
            $result.CommandElements[1].Extent.Text | Should-Be '-Be'

            $result.CommandElements[2].Extent.Text | Should-Be '$true'
        }
    }

    It 'Should return the correct CommandAst for Should -BeTrue' {
        InModuleScope -ScriptBlock {
            $mockAst = {
                Describe 'ShouldBe' [
                    It 'Should be true' {
                        $true | Should -BeTrue
                    }
            }.Ast

            $result = Get-PesterCommandAst -Ast $mockAst -CommandName 'Should'

            $result | Should-HaveType ([System.Management.Automation.Language.CommandAst])
            $result.CommandElements[0].Value | Should-Be 'Should'
            $result.CommandElements[0].Extent.Text | Should-Be 'Should'

            $result.CommandElements[1].ParameterName | Should-Be 'BeTrue'
            $result.CommandElements[1].Extent.Text | Should-Be '-BeTrue'

            $result.CommandElements[2].Extent.Text | Should-BeNull
        }
    }

    It 'Should return the correct CommandAst''s when there are multiple Should' {
        InModuleScope -ScriptBlock {
            $mockAst = {
                Describe 'ShouldBe' [
                    It 'Should be true' {
                        $true | Should -BeTrue
                    }

                    It 'Should be false' {
                        $true | Should -BeFalse
                    }
            }.Ast

            $result = Get-PesterCommandAst -Ast $mockAst -CommandName 'Should'

            $result.Count | Should-Be 2

            $result | Should-All { $_ | Should-HaveType ([System.Management.Automation.Language.CommandAst]) }

            # First Should
            $result[0].CommandElements[0].Value | Should-Be 'Should'
            $result[0].CommandElements[0].Extent.Text | Should-Be 'Should'

            $result[0].CommandElements[1].ParameterName | Should-Be 'BeTrue'
            $result[0].CommandElements[1].Extent.Text | Should-Be '-BeTrue'

            $result[0].CommandElements[2].Extent.Text | Should-BeNull

            # Second Should
            $result[1].CommandElements[0].Value | Should-Be 'Should'
            $result[1].CommandElements[0].Extent.Text | Should-Be 'Should'

            $result[1].CommandElements[1].ParameterName | Should-Be 'BeFalse'
            $result[1].CommandElements[1].Extent.Text | Should-Be '-BeFalse'

            $result[1].CommandElements[2].Extent.Text | Should-BeNull
        }
    }
}
