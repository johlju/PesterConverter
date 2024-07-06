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

Describe 'Get-PesterCommandParameter' {
    Context 'When the command is ''Should''' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockDefaultParameters = @{
                    CommandName         = 'Should'
                    IgnoreParameter     = @('Be', 'Not')
                    PositionalParameter = @('ExpectedValue', 'Because', 'ActualValue')
                }
            }
        }

        Context 'When there are no other properties than the operator name' {
            It 'Should return no properties' {
                InModuleScope -ScriptBlock {
                    $mockCommandAst = {
                        Should -Be
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Get-PesterCommandParameter -CommandAst $mockCommandAst @mockDefaultParameters

                    $result | Should-HaveType -Expected ([System.Collections.Hashtable])
                    $result.Keys.Count | Should -Be 0
                }
            }
        }

        Context 'When there are no positional parameters' {
            It 'Should return no properties' {
                InModuleScope -ScriptBlock {
                    $mockCommandAst = {
                        Should -Be -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Get-PesterCommandParameter -CommandAst $mockCommandAst @mockDefaultParameters

                    $result | Should-HaveType -Expected ([System.Collections.Hashtable])
                    $result.Keys.Count | Should -Be 0
                }
            }
        }

        Context 'When there are only positional parameters' {
            It 'Should return the correct positional parameters in the correct order' {
                InModuleScope -ScriptBlock {
                    $mockCommandAst = {
                        Should 'ExpectedString' 'BecauseString' 'ActualString' -Be
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Get-PesterCommandParameter -CommandAst $mockCommandAst @mockDefaultParameters

                    $result | Should-HaveType -Expected ([System.Collections.Hashtable])
                    $result | Should-BeEquivalent @{
                        ActualValue   = @{
                            ExtentText = "'ActualString'"
                            Position   = 3
                            Positional = $true
                        }
                        Because       = @{
                            ExtentText = "'BecauseString'"
                            Position   = 2
                            Positional = $true
                        }
                        ExpectedValue = @{
                            ExtentText = "'ExpectedString'"
                            Position   = 1
                            Positional = $true
                        }
                    }
                }
            }
        }

        Context 'When there are both positional and named parameters' {
            Context 'When the command is `Should "ExpectedString" -Be -ActualValue "ActualString" -Not` to be parsed' {
                It 'Should return the positional parameters in the correct order' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAst = {
                            Should "ExpectedString" -Be -ActualValue "ActualString" -Not
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Get-PesterCommandParameter -CommandAst $mockCommandAst @mockDefaultParameters

                        $result | Should-HaveType -Expected ([System.Collections.Hashtable])
                        $result | Should-BeEquivalent @{
                            ActualValue   = @{
                                ExtentText = '"ActualString"'
                                Position   = 0
                                Positional = $false
                            }
                            ExpectedValue = @{
                                ExtentText = '"ExpectedString"'
                                Position   = 1
                                Positional = $true
                            }
                        }
                    }
                }
            }

            Context 'When the command is `Should ''ExpectedString'' -Be -ActualValue ''ActualString'' -Not` to be parsed' {
                It 'Should return the positional parameters in the correct order' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAst = {
                            Should 'ExpectedString' -Be -ActualValue 'ActualString' -Not
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Get-PesterCommandParameter -CommandAst $mockCommandAst @mockDefaultParameters

                        $result | Should-HaveType -Expected ([System.Collections.Hashtable])
                        $result | Should-BeEquivalent @{
                            ActualValue   = @{
                                ExtentText = "'ActualString'"
                                Position   = 0
                                Positional = $false
                            }
                            ExpectedValue = @{
                                ExtentText = "'ExpectedString'"
                                Position   = 1
                                Positional = $true
                            }
                        }
                    }
                }
            }

            Context 'When the command is `Should -Be $false -Because ''mock should test correct value'' $false` to be parsed' {
                It 'Should return the positional parameters in the correct order' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAst = {
                            Should -Be $false -Because 'mock should test correct value' $false
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Get-PesterCommandParameter -CommandAst $mockCommandAst @mockDefaultParameters

                        $result | Should-HaveType -Expected ([System.Collections.Hashtable])
                        $result | Should-BeEquivalent @{
                            ActualValue   = @{
                                ExtentText = '$false'
                                Position   = 3
                                Positional = $true
                            }
                            Because       = @{
                                ExtentText = "'mock should test correct value'"
                                Position   = 0
                                Positional = $false
                            }
                            ExpectedValue = @{
                                ExtentText = '$false'
                                Position   = 1
                                Positional = $true
                            }
                        }
                    }
                }
            }
        }
    }
}
