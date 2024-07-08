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

Describe 'Convert-ShouldMatch' {
    Context 'When converting Pester 5 syntax to Pester 6 syntax' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues['Convert-ShouldMatch:Pester6'] = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues.Remove('Convert-ShouldMatch:Pester6')
            }
        }

        Context 'When the tests are affirming' {
            It 'Should convert `Should -Match ''Test''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match 'Test'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString ''Test'''
                }
            }

            It 'Should convert `Should -Match "ExpectedString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match "ExpectedString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString "ExpectedString"'
                }
            }

            It 'Should convert `Should -Match ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Match $anyValue` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match $anyValue
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString $anyValue'
                }
            }

            It 'Should convert `Should -ActualValue ''ExpectedString'' -Match ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ExpectedString' -Match 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'' -Actual ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Match ''ExpectedString'' -ActualValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match 'ExpectedString' -ActualValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'' -Actual ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ExpectedString'' -Match -RegularExpression ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ExpectedString' -Match -RegularExpression 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Match -ActualValue ''ExpectedString'' -RegularExpression ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match -ActualValue 'ExpectedString' -RegularExpression 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Match -RegularExpression ''ExpectedString'' -ActualValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match -RegularExpression 'ExpectedString' -ActualValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -RegularExpression ''ExpectedString'' -Match -ActualValue ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -RegularExpression 'ExpectedString' -Match -ActualValue 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -RegularExpression ''ExpectedString'' -ActualValue ''ExpectedString'' -Match` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -RegularExpression 'ExpectedString' -ActualValue 'ExpectedString' -Match
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -Actual ''ExpectedString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Not:$false -Match ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        $false | Should -Not:$false -Match 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Match (Get-Something)` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        function Get-Something { return 'ExpectedString' }
                        'ExpectedString' | Should -Match (Get-Something)
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString (Get-Something)'
                }
            }

            It 'Should convert `Should -Match ''ExpectedString'' -Because ''mock should test correct value'' ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match 'ExpectedString' -Because 'mock should test correct value' 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'' ''ExpectedString'' -Because ''mock should test correct value'''
                }
            }

            It 'Should convert `Should -Match ''ExpectedString'' ''mock should test correct value'' ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match 'ExpectedString' 'mock should test correct value' 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'' ''ActualString'' -Because ''mock should test correct value'''
                }
            }

            It 'Should convert `Should ''ExpectedString'' ''mock should test correct value'' ''ActualString'' -Match` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should 'ExpectedString' 'mock should test correct value' 'ActualString' -Match
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'' ''ActualString'' -Because ''mock should test correct value'''
                }
            }
        }

        Context 'When the tests are negated' {
            It 'Should convert `Should -Not -Match ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -Match 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Match ''Test'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match 'Test' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''Test'''
                }
            }

            It 'Should convert `Should -Not -Match "ExpectedString"` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -Match "ExpectedString"
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString "ExpectedString"'
                }
            }

            It 'Should convert `Should -Not -Match $anyValue` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -Match $anyValue
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString $anyValue'
                }
            }

            It 'Should convert `Should -Match $anyValue -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match $anyValue -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString $anyValue'
                }
            }

            It 'Should convert `Should -Not:$true -Match ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        $false | Should -Not:$true -Match 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''ExpectedString'''
                }
            }

            It 'Should convert `Should -Not -ActualValue ''ActualString'' -Match ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -ActualValue 'ActualString' -Match 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -Not -Match ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -Not -Match 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -Match ''ExpectedString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -Match 'ExpectedString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -Match ''ExpectedString'' -ActualValue ''ActualString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match 'ExpectedString' -ActualValue 'ActualString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -Match ''ExpectedString'' -Not -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match 'ExpectedString' -Not -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -Not -Match ''ExpectedString'' -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -Match 'ExpectedString' -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''ExpectedString'' -Actual ''ActualString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -Match -Not -RegularExpression ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -Match -Not -RegularExpression 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -Not -Match -RegularExpression ''ExpectedString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -Not -Match -RegularExpression 'ExpectedString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }

            It 'Should convert `Should -ActualValue ''ActualString'' -Match -RegularExpression ''ExpectedString'' -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'ActualString' -Match -RegularExpression 'ExpectedString' -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotMatchString -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When tests should always use named parameters' {
            It 'Should convert `Should -Match ''ExpectedString'' -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Match 'ExpectedString' -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-MatchString -Actual ''ActualString'' -Expected ''ExpectedString'''
                }
            }
        }

        Context 'When tests should always use positional parameters' {
            Context 'When the tests are affirming' {
                It 'Should convert `Should -Match ''ExpectedString'' -ActualValue ''ActualString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Match 'ExpectedString' -ActualValue 'ActualString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'' ''ActualString'''
                    }
                }

                It 'Should convert `Should -Match ''ExpectedString'' -ActualValue ''ActualString'' -Because "this must return true"` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Match 'ExpectedString' -ActualValue 'ActualString' -Because "this must return true"
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }

                It 'Should convert `Should -Match ''ExpectedString'' -Because "this must return true" -ActualValue ''ActualString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Match 'ExpectedString' -Because "this must return true" -ActualValue 'ActualString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }

                It 'Should convert `Should -Because "this must return true" -ActualValue ''ActualString'' -Match ''ExpectedString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Because "this must return true" -ActualValue 'ActualString' -Match 'ExpectedString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-MatchString ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }
            }

            Context 'When the tests are negated' {
                It 'Should convert `Should -Match ''ExpectedString'' -ActualValue ''ActualString'' -Because "this must return true" -Not` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Match 'ExpectedString' -ActualValue 'ActualString' -Because "this must return true" -Not
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldMatch -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-NotMatchString ''ExpectedString'' ''ActualString'' -Because "this must return true"'
                    }
                }
            }
        }
    }
}
