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

        It 'Should convert to Pester 6 syntax without using command aliases' {
            InModuleScope -ScriptBlock {
                $mockCommandAstPester5 = {
                    Should -BeExactly 'Test'
                }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -NoCommandAlias

                $result | Should-BeString -CaseSensitive 'Assert-StringEqual -CaseSensitive ''Test'''
            }
        }

        It 'Should convert to Pester 6 syntax using command aliases' {
            InModuleScope -ScriptBlock {
                $mockCommandAstPester5 = {
                    Should -BeExactly 'Test'
                }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''Test'''
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

            It 'Should convert `Should -BeExactly "AnyString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly "AnyString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive "AnyString"'
                }
            }

            It 'Should convert `Should -BeExactly ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive "Should-BeString -CaseSensitive 'AnyString'"
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

            It 'Should convert `Should -ActualValue ''AnyString'' -BeExactly ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'AnyString' -BeExactly 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''AnyString'' -Actual ''AnyString'''
                }
            }

            It 'Should convert `Should -BeExactly ''AnyString'' -ActualValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'AnyString' -ActualValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''AnyString'' -Actual ''AnyString'''
                }
            }

            It 'Should convert `Should -ActualValue ''AnyString'' -BeExactly -ExpectedValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'AnyString' -BeExactly -ExpectedValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Actual ''AnyString'' -Expected ''AnyString'''
                }
            }

            It 'Should convert `Should -BeExactly -ActualValue ''AnyString'' -ExpectedValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly -ActualValue 'AnyString' -ExpectedValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Actual ''AnyString'' -Expected ''AnyString'''
                }
            }

            It 'Should convert `Should -BeExactly -ExpectedValue ''AnyString'' -ActualValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly -ExpectedValue 'AnyString' -ActualValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Expected ''AnyString'' -Actual ''AnyString'''
                }
            }

            It 'Should convert `Should -ExpectedValue ''AnyString'' -BeExactly -ActualValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ExpectedValue 'AnyString' -BeExactly -ActualValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Expected ''AnyString'' -Actual ''AnyString'''
                }
            }

            It 'Should convert `Should -ExpectedValue ''AnyString'' -ActualValue ''AnyString'' -BeExactly` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ExpectedValue 'AnyString' -ActualValue 'AnyString' -BeExactly
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Expected ''AnyString'' -Actual ''AnyString'''
                }
            }

            It 'Should convert `Should -Not:$false -BeExactly ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        $false | Should -Not:$false -BeExactly 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''AnyString'''
                }
            }
        }

        Context 'When the tests are negated' {
            It 'Should convert `Should -Not -Be ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeExactly 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''AnyString'''
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

            It 'Should convert `Should -Not -BeExactly "AnyString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeExactly "AnyString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive "AnyString"'
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

            It 'Should convert `Should -Not:$true -BeExactly ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        $false | Should -Not:$true -BeExactly 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''AnyString'''
                }
            }

            It 'Should convert `Should -Not -ActualValue ''SpecificString'' -BeExactly ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -ActualValue 'SpecificString' -BeExactly 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''AnyString'' -Actual ''SpecificString'''
                }
            }

            It 'Should convert `Should -ActualValue ''SpecificString'' -Not -BeExactly ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'SpecificString' -Not -BeExactly 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''AnyString'' -Actual ''SpecificString'''
                }
            }

            It 'Should convert `Should -ActualValue ''SpecificString'' -BeExactly ''AnyString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'SpecificString' -BeExactly 'AnyString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''AnyString'' -Actual ''SpecificString'''
                }
            }

            It 'Should convert `Should -BeExactly ''AnyString'' -ActualValue ''SpecificString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'AnyString' -ActualValue 'SpecificString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''AnyString'' -Actual ''SpecificString'''
                }
            }

            It 'Should convert `Should -BeExactly ''AnyString'' -Not -ActualValue ''SpecificString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'AnyString' -Not -ActualValue 'SpecificString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''AnyString'' -Actual ''SpecificString'''
                }
            }

            It 'Should convert `Should -Not -BeExactly ''AnyString'' -ActualValue ''SpecificString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeExactly 'AnyString' -ActualValue 'SpecificString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''AnyString'' -Actual ''SpecificString'''
                }
            }

            It 'Should convert `Should -ActualValue ''SpecificString'' -BeExactly -Not -ExpectedValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'SpecificString' -BeExactly -Not -ExpectedValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive -Actual ''SpecificString'' -Expected ''AnyString'''
                }
            }

            It 'Should convert `Should -ActualValue ''SpecificString'' -Not -BeExactly -ExpectedValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'SpecificString' -Not -BeExactly -ExpectedValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive -Actual ''SpecificString'' -Expected ''AnyString'''
                }
            }

            It 'Should convert `Should -ActualValue ''SpecificString'' -BeExactly -ExpectedValue ''AnyString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'SpecificString' -BeExactly -ExpectedValue 'AnyString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive -Actual ''SpecificString'' -Expected ''AnyString'''
                }
            }
        }

        Context 'When tests should always use named parameters' {
            It 'Should convert `Should -BeExactly ''AnyString'' -ActualValue ''SpecificString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeExactly 'AnyString' -ActualValue 'SpecificString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive -Expected ''AnyString'' -Actual ''SpecificString'''
                }
            }
        }

        Context 'When tests should always use positional parameters' {
            Context 'When the tests are affirming' {
                It 'Should convert `Should -BeExactly ''AnyString'' -ActualValue ''SpecificString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -BeExactly 'AnyString' -ActualValue 'SpecificString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''AnyString'' ''SpecificString'''
                    }
                }

                It 'Should convert `Should -BeExactly ''AnyString'' -ActualValue ''SpecificString'' -Because "this must return true"` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -BeExactly 'AnyString' -ActualValue 'SpecificString' -Because "this must return true"
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''AnyString'' ''SpecificString'' -Because "this must return true"'
                    }
                }

                It 'Should convert `Should -BeExactly ''AnyString'' -Because "this must return true" -ActualValue ''SpecificString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -BeExactly 'AnyString' -Because "this must return true" -ActualValue 'SpecificString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''AnyString'' -Because "this must return true" ''SpecificString'''
                    }
                }

                It 'Should convert `Should -Because "this must return true" -ActualValue ''SpecificString'' -BeExactly ''AnyString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Because "this must return true" -ActualValue 'SpecificString' -BeExactly 'AnyString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-BeString -CaseSensitive ''AnyString'' -Because "this must return true" ''SpecificString'''
                    }
                }
            }

            Context 'When the tests are negated' {
                It 'Should convert `Should -BeExactly ''AnyString'' -ActualValue ''SpecificString'' -Because "this must return true" -Not` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -BeExactly 'AnyString' -ActualValue 'SpecificString' -Because "this must return true" -Not
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-NotBeString -CaseSensitive ''AnyString'' ''SpecificString'' -Because "this must return true"'
                    }
                }
            }
        }
    }
}
