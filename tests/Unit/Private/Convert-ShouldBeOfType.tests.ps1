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

Describe 'Convert-ShouldBeOfType' {
    Context 'When converting Pester 5 syntax to Pester 6 syntax' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues['Convert-ShouldBeOfType:Pester6'] = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues.Remove('Convert-ShouldBeOfType:Pester6')
            }
        }

        Context 'When the tests are affirming' {
            It 'Should convert `Should -BeOfType ''System.String''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeOfType 'System.String'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType ''System.String'''
                }
            }

            It 'Should convert `Should -BeOfType [System.String]` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeOfType [System.String]
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType ([System.String])'
                }
            }

            It 'Should convert `Should -BeOfType [System.String] ''BecauseString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeOfType [System.String] 'BecauseString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType ([System.String]) -Because ''BecauseString'''
                }
            }


            It 'Should convert `Should -ActualValue ''AnyString'' [System.String] -BeOfType ''BecauseString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'AnyString' [System.String] -BeOfType 'BecauseString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType ([System.String]) -Actual ''AnyString'' -Because ''BecauseString'''
                }
            }

            It 'Should convert `Should -ActualValue ''AnyString'' [System.String] -BeOfType -Because ''BecauseString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'AnyString' [System.String] -BeOfType 'BecauseString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType ([System.String]) -Actual ''AnyString'' -Because ''BecauseString'''
                }
            }

            It 'Should convert `Should -ActualValue ''AnyString'' -ExpectedValue [System.String] -BeOfType -Because ''BecauseString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ActualValue 'AnyString' -ExpectedValue [System.String] -BeOfType -Because 'BecauseString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType -Actual ''AnyString'' -Because ''BecauseString'' -Expected ([System.String])'
                }
            }

            It 'Should convert `Should -BeOfType [System.String] -ActualValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeOfType [System.String] -ActualValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType ([System.String]) -Actual ''AnyString'''
                }
            }

            It 'Should convert `Should -ExpectedValue [System.String] -ActualValue ''AnyString'' -BeOfType` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -ExpectedValue [System.String] -ActualValue 'AnyString' -BeOfType
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType -Actual ''AnyString'' -Expected ([System.String])'
                }
            }

            It 'Should convert `Should -Not:$false -ExpectedValue [System.String] -ActualValue ''AnyString'' -BeOfType` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeOfType -Not:$false -ExpectedValue [System.String] -ActualValue 'AnyString' -BeOfType
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType -Actual ''AnyString'' -Expected ([System.String])'
                }
            }

            It 'Should convert `Should -BeOfType (Get-Something)` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        function Get-Something { return ([System.String]) }
                        'AnyString' | Should -BeOfType (Get-Something)
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-HaveType (Get-Something)'
                }
            }
        }

        Context 'When the tests are negated' {
            It 'Should convert `Should -Not -Be 1` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeOfType [System.String]
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotHaveType ([System.String])'
                }
            }

            It 'Should convert `Should -BeOfType [System.String] -Not` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeOfType [System.String] -Not
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotHaveType ([System.String])'
                }
            }

            It 'Should convert `Should -Not -BeOfType $anyValue` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeOfType $anyValue
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-NotHaveType $anyValue'
                }
            }
        }

        Context 'When tests should always use named parameters' {
            It 'Should convert `Should -BeOfType [System.String] ''BecauseString'' -ActualValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeOfType [System.String] 'BecauseString' -ActualValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-HaveType -Actual ''AnyString'' -Because ''BecauseString'' -Expected ([System.String])'
                }
            }
        }

        Context 'When alias operator name is used' {
            It 'Should convert `Should -HaveType [System.String] -ActualValue ''AnyString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -HaveType [System.String] -ActualValue 'AnyString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-HaveType -Actual ''AnyString'' -Expected ([System.String])'
                }
            }
        }

        Context 'When tests should always use positional parameters' {
            Context 'When the tests are affirming' {
                It 'Should convert `Should -HaveType -ExpectedValue ([System.String]) -ActualValue ''AnyString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -HaveType -ExpectedValue ([System.String]) -ActualValue 'AnyString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-HaveType ([System.String]) ''AnyString'''
                    }
                }

                It 'Should convert `Should -HaveType -ExpectedValue ([System.String]) -ActualValue ''AnyString'' -Because ''BecauseString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -HaveType -ExpectedValue ([System.String]) -ActualValue 'AnyString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-HaveType ([System.String]) ''AnyString'''
                    }
                }
            }

            Context 'When the tests are negated' {
                It 'Should convert `Should -HaveType -ExpectedValue ([System.String]) -Not -ActualValue ''AnyString'' -Because ''BecauseString''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -HaveType -ExpectedValue ([System.String]) -Not -ActualValue 'AnyString' -Because 'BecauseString'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldBeOfType -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-NotHaveType ([System.String]) ''AnyString'' -Because ''BecauseString'''
                    }
                }
            }
        }
    }
}
