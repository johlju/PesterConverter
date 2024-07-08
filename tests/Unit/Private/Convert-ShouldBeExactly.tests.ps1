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

Describe 'Convert-ShouldBeExactly' {
    Context 'When converting Pester 5 syntax to Pester 6 syntax' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues['Convert-ShouldBeExactly:Pester6'] = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues.Remove('Convert-ShouldBeExactly:Pester6')
            }
        }

        Context 'When the tests are affirming' {
            It 'Should convert `Should -BeExactly ''Test''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'Test'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''Test'''
                }
            }

            It 'Should convert `Should -BeExactly "ExpectedString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly "ExpectedString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive "ExpectedString"'
                }
            }

            It 'Should convert `Should -BeExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive "Should-BeString -CaseSensitive 'ExpectedString'"
                }
            }

            It 'Should convert `Should -BeExactly $anyValue` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly $anyValue
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive $anyValue'
                }
            }

            It 'Should convert `Should -ActualValue ''ExpectedString'' -BeExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ExpectedString' -BeExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'' -Actual ''ExpectedString'''
                }
            }

            It 'Should convert `Should -BeExactly ''ExpectedString'' -ActualValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'ExpectedString' -ActualValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'' -Actual ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ExpectedString'' -BeExactly -ExpectedValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ExpectedString' -BeExactly -ExpectedValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -BeExactly -ActualValue ''ExpectedString'' -ExpectedValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly -ActualValue 'ExpectedString' -ExpectedValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -BeExactly -ExpectedValue ''ExpectedString'' -ActualValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly -ExpectedValue 'ExpectedString' -ActualValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ExpectedValue ''ExpectedString'' -BeExactly -ActualValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ExpectedValue 'ExpectedString' -BeExactly -ActualValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ExpectedValue ''ExpectedString'' -ActualValue ''ExpectedString'' -BeExactly` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ExpectedValue 'ExpectedString' -ActualValue 'ExpectedString' -BeExactly
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Not:$false -BeExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        $false | Should -Not:$false -BeExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'''
                }
            }

            It 'Should convert `Should -BeExactly (Get-Something)` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        function Get-Something { return 'ExpectedString' }
                        'ExpectedString' | Should -BeExactly (Get-Something)
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive (Get-Something)'
                }
            }

            It 'Should convert `Should -BeExactly ''ExpectedString'' -Because ''mock should test correct value'' ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'ExpectedString' -Because 'mock should test correct value' 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'' ''ExpectedString'' -Because ''mock should test correct value'''
                }
            }

            It 'Should convert `Should -BeExactly ''ExpectedString'' ''mock should test correct value'' ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'ExpectedString' 'mock should test correct value' 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because ''mock should test correct value'''
                }
            }

            It 'Should convert `Should ''ExpectedString'' ''mock should test correct value'' ''ActualString'' -BeExactly` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should 'ExpectedString' 'mock should test correct value' 'ActualString' -BeExactly
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because ''mock should test correct value'''
                }
            }
        }

        Context 'When the tests are negated' {
            It 'Should convert `Should -Not -Be ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''ExpectedString'''
                }
            }

            It 'Should convert `Should -BeExactly ''Test'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'Test' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''Test'''
                }
            }

            It 'Should convert `Should -Not -BeExactly "ExpectedString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeExactly "ExpectedString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive "ExpectedString"'
                }
            }

            It 'Should convert `Should -Not -BeExactly $anyValue` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeExactly $anyValue
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive $anyValue'
                }
            }

            It 'Should convert `Should -BeExactly $anyValue -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly $anyValue -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive $anyValue'
                }
            }

            It 'Should convert `Should -Not:$true -BeExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        $false | Should -Not:$true -BeExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Not -ActualValue ''ActualString'' -BeExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -ActualValue 'ActualString' -BeExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -Not -BeExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -Not -BeExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -BeExactly ''ExpectedString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -BeExactly 'ExpectedString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -BeExactly ''ExpectedString'' -ActualValue ''ActualString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'ExpectedString' -ActualValue 'ActualString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -BeExactly ''ExpectedString'' -Not -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'ExpectedString' -Not -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -Not -BeExactly ''ExpectedString'' -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeExactly 'ExpectedString' -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -BeExactly -Not -ExpectedValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -BeExactly -Not -ExpectedValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -Not -BeExactly -ExpectedValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -Not -BeExactly -ExpectedValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -BeExactly -ExpectedValue ''ExpectedString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -BeExactly -ExpectedValue 'ExpectedString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When alias operator name is used' {
            It 'Should convert `Should -EQ $true -ActualValue $true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -CEQ 'ExpectedString' -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When tests should always use named parameters' {
            It 'Should convert `Should -BeExactly ''ExpectedString'' -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'ExpectedString' -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When tests should always use positional parameters' {
            Context 'When the tests are affirming' {
                It 'Should convert `Should -BeExactly ''ExpectedString'' -ActualValue ''ActualString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -BeExactly 'ExpectedString' -ActualValue 'ActualString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'' ''ActualString'''
                    }
                }

                It 'Should convert `Should -BeExactly ''ExpectedString'' -ActualValue ''ActualString'' -Because "this must return true"` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -BeExactly 'ExpectedString' -ActualValue 'ActualString' -Because "this must return true"
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }

                It 'Should convert `Should -BeExactly ''ExpectedString'' -Because "this must return true" -ActualValue ''ActualString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -BeExactly 'ExpectedString' -Because "this must return true" -ActualValue 'ActualString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }

                It 'Should convert `Should -Because "this must return true" -ActualValue ''ActualString'' -BeExactly ''ExpectedString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Because "this must return true" -ActualValue 'ActualString' -BeExactly 'ExpectedString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }
            }

            Context 'When the tests are negated' {
                It 'Should convert `Should -BeExactly ''ExpectedString'' -ActualValue ''ActualString'' -Because "this must return true" -Not` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -BeExactly 'ExpectedString' -ActualValue 'ActualString' -Because "this must return true" -Not
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }
            }
        }
    }
}
