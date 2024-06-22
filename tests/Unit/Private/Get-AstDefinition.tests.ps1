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

# Create a Describe block for the function Get-AstDefinition
Describe 'Get-AstDefinition' {
    BeforeAll {
        # Create mock script files in the Pester TestDrive
        $mockValidScriptPath1 = Join-Path -Path $TestDrive -ChildPath 'ValidScript1.ps1'
        Set-Content -Path $mockValidScriptPath1 -Value 'Write-Host "Hello, world!"'

        $mockValidScriptPath2 = Join-Path -Path $TestDrive -ChildPath 'ValidScript2.ps1'
        Set-Content -Path $mockValidScriptPath2 -Value 'Write-Host "Hello, world!"'

        $mockUnparsableScriptPath = Join-Path -Path $TestDrive -ChildPath 'UnparsableScript.ps1'
        # TODO: Change comment if ParseException is not thrown.
        # This script is missing a closing brace, so it will throw a ParseException when parsed.
        Set-Content -Path $mockUnparsableScriptPath -Value 'function a { Write-Host "Hello, world!"'

        # Add default parameter values for the mock script paths to the InModuleScope.
        $PSDefaultParameterValues['InModuleScope:Parameters'] = @{
            MockValidScriptPath1 = $mockValidScriptPath1
            MockValidScriptPath2 = $mockValidScriptPath2
            MockUnparsableScriptPath = $mockUnparsableScriptPath
        }
    }

    AfterAll {
        $PSDefaultParameterValues.Remove('InModuleScope:Parameters')
    }

    # Test if the function returns the expected output when given a valid file path
    It 'Should return the expected output for a valid file path' {
        InModuleScope -ScriptBlock {
            $result = Get-AstDefinition -Path $mockValidScriptPath1

            $result | Should-HaveType ([System.Management.Automation.Language.ScriptBlockAst])
        }
    }

    # Test if the function throws an error when given an invalid file path
    It 'Should throw an exception for an invalid file path' {
        InModuleScope -ScriptBlock {
            # TODO: Make sure it throws the expected error message.
            { Get-AstDefinition -Path "$TestDrive/MissingScript.ps1" } | Should-Throw -ExceptionMessage 'Failed to parse the script.*Could not find file*'
        }
    }

    # Test if the function handles multiple file paths correctly
    It 'Should handles multiple file paths correctly' {
        InModuleScope -ScriptBlock {
            $filePaths = $mockValidScriptPath1, $mockValidScriptPath2

            $result = Get-AstDefinition -Path $filePaths

            $result.Count | Should-Be 2
            $result | Should-All { $_ | Should-HaveType ([System.Management.Automation.Language.ScriptBlockAst]) }
        }
    }

    # Test if the function handles pipeline input correctly
    It 'Should handle pipeline input correctly' {
        InModuleScope -ScriptBlock {
            $result = $mockValidScriptPath1 | Get-AstDefinition

            $result | Should-HaveType ([System.Management.Automation.Language.ScriptBlockAst])
        }
    }

    # Test if the function throws the correct exception when given an unparsable script file
    It 'Should throw an exception for an unparsable script file' {
        InModuleScope -ScriptBlock {
            { Get-AstDefinition -Path $mockUnparsableScriptPath } | Should-Throw -ExceptionMessage 'Failed to parse the script.*Missing closing ''}''*'
        }
    }
}
