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

Describe 'Convert-ShouldMatchExactly' {
    Context 'When converting Pester 5 syntax to Pester 6 syntax' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues['Convert-ShouldMatchExactly:Pester6'] = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues.Remove('Convert-ShouldMatchExactly:Pester6')
            }
        }

        Context 'When the tests are affirming' {
            It 'Should convert `Should -MatchExactly ''Test''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly 'Test'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''Test'''
                }
            }

            It 'Should convert `Should -MatchExactly "ExpectedString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly "ExpectedString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive "ExpectedString"'
                }
            }

            It 'Should convert `Should -MatchExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'''
                }
            }

            It 'Should convert `Should -MatchExactly $anyValue` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly $anyValue
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive $anyValue'
                }
            }

            It 'Should convert `Should -ActualValue ''ExpectedString'' -MatchExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ExpectedString' -MatchExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'' -Actual ''ExpectedString'''
                }
            }

            It 'Should convert `Should -MatchExactly ''ExpectedString'' -ActualValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly 'ExpectedString' -ActualValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'' -Actual ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ExpectedString'' -MatchExactly -RegularExpression ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ExpectedString' -MatchExactly -RegularExpression 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -MatchExactly -ActualValue ''ExpectedString'' -RegularExpression ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly -ActualValue 'ExpectedString' -RegularExpression 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -MatchExactly -RegularExpression ''ExpectedString'' -ActualValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly -RegularExpression 'ExpectedString' -ActualValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -RegularExpression ''ExpectedString'' -MatchExactly -ActualValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -RegularExpression 'ExpectedString' -MatchExactly -ActualValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -RegularExpression ''ExpectedString'' -ActualValue ''ExpectedString'' -MatchExactly` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -RegularExpression 'ExpectedString' -ActualValue 'ExpectedString' -MatchExactly
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Not:$false -MatchExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        $false | Should -Not:$false -MatchExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'''
                }
            }

            It 'Should convert `Should -MatchExactly (Get-Something)` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        function Get-Something { return 'ExpectedString' }
                        'ExpectedString' | Should -MatchExactly (Get-Something)
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive (Get-Something)'
                }
            }

            It 'Should convert `Should -MatchExactly ''ExpectedString'' -Because ''mock should test correct value'' ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly 'ExpectedString' -Because 'mock should test correct value' 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'' ''ExpectedString'' -Because ''mock should test correct value'''
                }
            }

            It 'Should convert `Should -MatchExactly ''ExpectedString'' ''mock should test correct value'' ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly 'ExpectedString' 'mock should test correct value' 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because ''mock should test correct value'''
                }
            }

            It 'Should convert `Should ''ExpectedString'' ''mock should test correct value'' ''ActualString'' -MatchExactly` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should 'ExpectedString' 'mock should test correct value' 'ActualString' -MatchExactly
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because ''mock should test correct value'''
                }
            }
        }

        Context 'When the tests are negated' {
            It 'Should convert `Should -Not -MatchExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -MatchExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''ExpectedString'''
                }
            }

            It 'Should convert `Should -MatchExactly ''Test'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly 'Test' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''Test'''
                }
            }

            It 'Should convert `Should -Not -MatchExactly "ExpectedString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -MatchExactly "ExpectedString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive "ExpectedString"'
                }
            }

            It 'Should convert `Should -Not -MatchExactly $anyValue` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -MatchExactly $anyValue
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive $anyValue'
                }
            }

            It 'Should convert `Should -MatchExactly $anyValue -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly $anyValue -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive $anyValue'
                }
            }

            It 'Should convert `Should -Not:$true -MatchExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        $false | Should -Not:$true -MatchExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Not -ActualValue ''ActualString'' -MatchExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -ActualValue 'ActualString' -MatchExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -Not -MatchExactly ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -Not -MatchExactly 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -MatchExactly ''ExpectedString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -MatchExactly 'ExpectedString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -MatchExactly ''ExpectedString'' -ActualValue ''ActualString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly 'ExpectedString' -ActualValue 'ActualString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -MatchExactly ''ExpectedString'' -Not -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly 'ExpectedString' -Not -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -Not -MatchExactly ''ExpectedString'' -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -MatchExactly 'ExpectedString' -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -MatchExactly -Not -RegularExpression ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -MatchExactly -Not -RegularExpression 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -Not -MatchExactly -RegularExpression ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -Not -MatchExactly -RegularExpression 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -MatchExactly -RegularExpression ''ExpectedString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -MatchExactly -RegularExpression 'ExpectedString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When alias operator name is used' {
            It 'Should convert `Should -CMATCH $true -ActualValue $true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -CMATCH 'ExpectedString' -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When tests should always use named parameters' {
            It 'Should convert `Should -MatchExactly ''ExpectedString'' -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -MatchExactly 'ExpectedString' -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When tests should always use positional parameters' {
            Context 'When the tests are affirming' {
                It 'Should convert `Should -MatchExactly ''ExpectedString'' -ActualValue ''ActualString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -MatchExactly 'ExpectedString' -ActualValue 'ActualString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'' ''ActualString'''
                    }
                }

                It 'Should convert `Should -MatchExactly ''ExpectedString'' -ActualValue ''ActualString'' -Because "this must return true"` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -MatchExactly 'ExpectedString' -ActualValue 'ActualString' -Because "this must return true"
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }

                It 'Should convert `Should -MatchExactly ''ExpectedString'' -Because "this must return true" -ActualValue ''ActualString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -MatchExactly 'ExpectedString' -Because "this must return true" -ActualValue 'ActualString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }

                It 'Should convert `Should -Because "this must return true" -ActualValue ''ActualString'' -MatchExactly ''ExpectedString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Because "this must return true" -ActualValue 'ActualString' -MatchExactly 'ExpectedString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-MatchString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }
            }

            Context 'When the tests are negated' {
                It 'Should convert `Should -MatchExactly ''ExpectedString'' -ActualValue ''ActualString'' -Because "this must return true" -Not` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -MatchExactly 'ExpectedString' -ActualValue 'ActualString' -Because "this must return true" -Not
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatchExactly -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-NotMatchString -CaseSensitive ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }
            }
        }
    }
}
