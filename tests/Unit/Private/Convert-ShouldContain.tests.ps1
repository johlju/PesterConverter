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

Describe 'Convert-ShouldContain' {
    Context 'When converting Pester 5 syntax to Pester 6 syntax' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues['Convert-ShouldContain:Pester6'] = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues.Remove('Convert-ShouldContain:Pester6')
            }
        }

        Context 'When the tests are affirming' {
            It 'Should convert `Should -Contain ''Test''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain 'Test'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''Test'''
                }
            }

            It 'Should convert `Should -Contain "ExpectedString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain "ExpectedString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection "ExpectedString"'
                }
            }

            It 'Should convert `Should -Contain ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Contain $anyValue` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain $anyValue
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection $anyValue'
                }
            }

            It 'Should convert `Should -ActualValue @(''a'', ''b'') -Contain ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue @('a', 'b') -Contain 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'' -Actual @(''a'', ''b'')'
                }
            }

            It 'Should convert `Should -Contain ''ExpectedString'' -ActualValue @(''a'', ''b'')` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain 'ExpectedString' -ActualValue @('a', 'b')
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'' -Actual @(''a'', ''b'')'
                }
            }

            It 'Should convert `Should -ActualValue @(''a'', ''b'') -Contain -ExpectedValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue @('a', 'b') -Contain -ExpectedValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection -Actual @(''a'', ''b'') -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Contain -ActualValue @(''a'', ''b'') -ExpectedValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain -ActualValue @('a', 'b') -ExpectedValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection -Actual @(''a'', ''b'') -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Contain -ExpectedValue ''ExpectedString'' -ActualValue @(''a'', ''b'')` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain -ExpectedValue 'ExpectedString' -ActualValue @('a', 'b')
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection -Actual @(''a'', ''b'') -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ExpectedValue ''ExpectedString'' -Contain -ActualValue @(''a'', ''b'')` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ExpectedValue 'ExpectedString' -Contain -ActualValue @('a', 'b')
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection -Actual @(''a'', ''b'') -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ExpectedValue ''ExpectedString'' -ActualValue @(''a'', ''b'') -Contain` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ExpectedValue 'ExpectedString' -ActualValue @('a', 'b') -Contain
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection -Actual @(''a'', ''b'') -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Not:$false -Contain ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        @('a', 'b') | Should -Not:$false -Contain 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Contain (Get-Something)` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        function Get-Something { return 'ExpectedString' }
                        @('a', 'b') | Should -Contain (Get-Something)
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection (Get-Something)'
                }
            }

            It 'Should convert `Should -Contain ''ExpectedString'' -Because ''mock should test correct value''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain 'ExpectedString' -Because 'mock should test correct value'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'' -Because ''mock should test correct value'''
                }
            }

            It 'Should convert `Should -Contain ''ExpectedString'' ''mock should test correct value''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain 'ExpectedString' 'mock should test correct value'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'' -Because ''mock should test correct value'''
                }
            }

            It 'Should convert `Should ''ExpectedString'' ''mock should test correct value'' -Contain` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should 'ExpectedString' 'mock should test correct value' -Contain
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'' -Because ''mock should test correct value'''
                }
            }
        }

        Context 'When the tests are negated' {
            It 'Should convert `Should -Not -Contain ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -Contain 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Contain ''Test'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain 'Test' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''Test'''
                }
            }

            It 'Should convert `Should -Not -Contain "ExpectedString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -Contain "ExpectedString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection "ExpectedString"'
                }
            }

            It 'Should convert `Should -Not -Contain $anyValue` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -Contain $anyValue
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection $anyValue'
                }
            }

            It 'Should convert `Should -Contain $anyValue -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain $anyValue -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection $anyValue'
                }
            }

            It 'Should convert `Should -Not:$true -Contain ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        $false | Should -Not:$true -Contain 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Not -ActualValue @(''a'', ''b'') -Contain ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -ActualValue @('a', 'b') -Contain 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''ExpectedString'' -Actual @(''a'', ''b'')'
                }
            }

            It 'Should convert `Should -ActualValue @(''a'', ''b'') -Not -Contain ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue @('a', 'b') -Not -Contain 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''ExpectedString'' -Actual @(''a'', ''b'')'
                }
            }

            It 'Should convert `Should -ActualValue @(''a'', ''b'') -Contain ''ExpectedString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue @('a', 'b') -Contain 'ExpectedString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''ExpectedString'' -Actual @(''a'', ''b'')'
                }
            }

            It 'Should convert `Should -Contain ''ExpectedString'' -ActualValue @(''a'', ''b'') -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain 'ExpectedString' -ActualValue @('a', 'b') -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''ExpectedString'' -Actual @(''a'', ''b'')'
                }
            }

            It 'Should convert `Should -Contain ''ExpectedString'' -Not -ActualValue @(''a'', ''b'')` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain 'ExpectedString' -Not -ActualValue @('a', 'b')
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''ExpectedString'' -Actual @(''a'', ''b'')'
                }
            }

            It 'Should convert `Should -Not -Contain ''ExpectedString'' -ActualValue @(''a'', ''b'')` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -Contain 'ExpectedString' -ActualValue @('a', 'b')
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''ExpectedString'' -Actual @(''a'', ''b'')'
                }
            }

            It 'Should convert `Should -ActualValue @(''a'', ''b'') -Contain -Not -ExpectedValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue @('a', 'b') -Contain -Not -ExpectedValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection -Actual @(''a'', ''b'') -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue @(''a'', ''b'') -Not -Contain -ExpectedValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue @('a', 'b') -Not -Contain -ExpectedValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection -Actual @(''a'', ''b'') -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue @(''a'', ''b'') -Contain -ExpectedValue ''ExpectedString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue @('a', 'b') -Contain -ExpectedValue 'ExpectedString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotContainCollection -Actual @(''a'', ''b'') -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When tests should always use named parameters' {
            It 'Should convert `Should -Contain ''ExpectedString'' ''BecauseString'' -ActualValue @(''a'', ''b'')` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Contain 'ExpectedString' 'BecauseString' -ActualValue @('a', 'b')
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-ContainCollection -Actual @(''a'', ''b'') -Because ''BecauseString'' -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When tests should always use positional parameters' {
            Context 'When the tests are affirming' {
                It 'Should convert `Should -Contain ''ExpectedString'' -ActualValue @(''a'', ''b'')` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Contain 'ExpectedString' -ActualValue @('a', 'b')
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'' @(''a'', ''b'')'
                    }
                }

                It 'Should convert `Should -Contain ''ExpectedString'' -ActualValue @(''a'', ''b'') -Because "this must return true"` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Contain 'ExpectedString' -ActualValue @('a', 'b') -Because "this must return true"
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'' @(''a'', ''b'') -Because "this must return true"'
                    }
                }

                It 'Should convert `Should -Contain ''ExpectedString'' -Because "this must return true" -ActualValue @(''a'', ''b'')` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Contain 'ExpectedString' -Because "this must return true" -ActualValue @('a', 'b')
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'' @(''a'', ''b'') -Because "this must return true"'
                    }
                }

                It 'Should convert `Should -Because "this must return true" -ActualValue @(''a'', ''b'') -Contain ''ExpectedString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Because "this must return true" -ActualValue @('a', 'b') -Contain 'ExpectedString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-ContainCollection ''ExpectedString'' @(''a'', ''b'') -Because "this must return true"'
                    }
                }
            }

            Context 'When the tests are negated' {
                It 'Should convert `Should -Contain ''ExpectedString'' -ActualValue @(''a'', ''b'') -Because "this must return true" -Not` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Contain 'ExpectedString' -ActualValue @('a', 'b') -Because "this must return true" -Not
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldContain -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-NotContainCollection ''ExpectedString'' @(''a'', ''b'') -Because "this must return true"'
                    }
                }
            }
        }
    }
}
