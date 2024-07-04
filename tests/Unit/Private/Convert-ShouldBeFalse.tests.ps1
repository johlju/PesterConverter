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

Describe 'Convert-ShouldBeFalse' {
    Context 'When converting Pester 5 syntax to Pester 6 syntax' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues['Convert-ShouldBeFalse:Pester6'] = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues.Remove('Convert-ShouldBeFalse:Pester6')
            }
        }

        Context 'When the tests are affirming' {
            It 'Should convert `Should -BeFalse` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse'
                }
            }

            It 'Should convert `Should -BeFalse -Because ''BecauseMockString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse -Because 'BecauseMockString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse -Because ''BecauseMockString'''
                }
            }

            It 'Should convert `Should -BeFalse -ActualValue $true -Because ''BecauseMockString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse -ActualValue $true -Because 'BecauseMockString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse -Actual $true -Because ''BecauseMockString'''
                }
            }

            It 'Should convert `Should -BeFalse ''BecauseMockString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse 'BecauseMockString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse ''BecauseMockString'''
                }
            }

            It 'Should convert `Should -BeFalse ''BecauseMockString'' $true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse 'BecauseMockString' $true
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse $true ''BecauseMockString'''
                }
            }

            It 'Should convert `Should -Not:$false -BeFalse ''BecauseMockString'' $true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not:$false -BeFalse 'BecauseMockString' $true
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse $true ''BecauseMockString'''
                }
            }

            It 'Should convert `Should -BeFalse -ActualValue $true ''BecauseMockString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse -ActualValue $true 'BecauseMockString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse ''BecauseMockString'' -Actual $true'
                }
            }

            It 'Should convert `Should -BeFalse ''BecauseMockString'' -ActualValue $true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse 'BecauseMockString' -ActualValue $true
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse ''BecauseMockString'' -Actual $true'
                }
            }

            It 'Should convert `Should -BeFalse -Because ''BecauseMockString'' $true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse -Because 'BecauseMockString' $true
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse $true -Because ''BecauseMockString'''
                }
            }

            It 'Should convert `Should -BeFalse $true -Because ''BecauseMockString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse -Because 'BecauseMockString' $true
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse $true -Because ''BecauseMockString'''
                }
            }

            It 'Should convert `Should -BeFalse ''BecauseMockString'' (Get-BooleanValue)` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse 'BecauseMockString' (Get-BooleanValue)
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse (Get-BooleanValue) ''BecauseMockString'''
                }
            }

            It 'Should convert `Should -BeFalse -ActualValue $true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse -ActualValue $true
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse -Actual $true'
                }
            }
        }

        Context 'When the tests are negated' {
            It 'Should convert `Should -Not -BeFalse` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -BeFalse
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeTrue'
                }
            }

            It 'Should convert `Should -BeFalse -Not:$true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse -Not:$true
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-BeTrue'
                }
            }
        }

        Context 'When tests should always use named parameters' {
            It 'Should convert `Should -BeFalse ''BecauseMockString'' $true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse 'BecauseMockString' $true
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse -Actual $true -Because ''BecauseMockString'''
                }
            }
        }

        Context 'When tests should always use positional parameters' {
            It 'Should convert `Should -BeFalse -Because ''BecauseMockString'' -ActualValue $true` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -BeFalse -Because 'BecauseMockString' -ActualValue $true
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldBeFalse -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                    $result | Should-BeString -CaseSensitive 'Should-BeFalse $true ''BecauseMockString'''
                }
            }
        }
    }
}
