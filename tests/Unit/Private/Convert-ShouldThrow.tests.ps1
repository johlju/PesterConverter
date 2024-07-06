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

Describe 'Convert-ShouldThrow' {
    Context 'When converting Pester 5 syntax to Pester 6 syntax' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues['Convert-ShouldThrow:Pester6'] = $true
            }
        }

        AfterAll {
            InModuleScope -ScriptBlock {
                $PSDefaultParameterValues.Remove('Convert-ShouldThrow:Pester6')
            }
        }

        Context 'When the tests are affirming' {
            It 'Should convert `Should -Throw` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Throw
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldThrow -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-Throw'
                }
            }

            It 'Should convert `Should -Throw ''MockErrorMessage'' ''MockErrorId'' ([System.Exception]) ''BecauseString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Throw 'MockErrorMessage' 'MockErrorId' ([System.Exception]) 'BecauseString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldThrow -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-Throw ''MockErrorMessage'' ''MockErrorId'' ([System.Exception]) ''BecauseString'''
                }
            }

            It 'Should convert `Should -Throw ''MockErrorMessage'' ''MockErrorId'' ([System.Exception])` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Throw 'MockErrorMessage' 'MockErrorId' ([System.Exception])
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldThrow -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-Throw ''MockErrorMessage'' ''MockErrorId'' ([System.Exception])'
                }
            }

            It 'Should convert `Should -Throw ''MockErrorMessage'' ''MockErrorId''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Throw 'MockErrorMessage' 'MockErrorId'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldThrow -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-Throw ''MockErrorMessage'' ''MockErrorId'''
                }
            }

            It 'Should convert `Should -Throw ''MockErrorMessage''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Throw 'MockErrorMessage'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldThrow -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-Throw ''MockErrorMessage'''
                }
            }

            It 'Should convert `Should -Throw -ExceptionType ([System.Exception]) -ErrorId ''MockErrorId'' -Because ''BecauseString'' -ExceptionMessage ''MockErrorMessage''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Throw -Because 'BecauseString' -ExceptionType ([System.Exception]) -ErrorId 'MockErrorId' -ExceptionMessage 'MockErrorMessage'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldThrow -CommandAst $mockCommandAstPester5

                    $result | Should-BeString -CaseSensitive 'Should-Throw -Because ''BecauseString'' -ExceptionMessage ''MockErrorMessage'' -ExceptionType ([System.Exception]) -FullyQualifiedErrorId ''MockErrorId'''
                }
            }

            It 'Should convert `Should -Throw -ExceptionType ([System.Exception]) -ErrorId ''MockErrorId'' -Because ''BecauseString'' -ExceptionMessage ''MockErrorMessage'' -ActualValue { Write-Error -Message ''MockErrorMessage'' -ErrorId ''MockErrorId'' -Category ''InvalidOperation'' -TargetObject ''MockTargetObject'' -ErrorAction ''Stop'' }` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Throw -Because 'BecauseString' -ExceptionType ([System.Exception]) -ErrorId 'MockErrorId' -ExceptionMessage 'MockErrorMessage' -ActualValue {
                            Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
                        }
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldThrow -CommandAst $mockCommandAstPester5

                    # This need to have the blank space at the start of second and third row for it to match.
                    $result | Should-BeString -CaseSensitive "Should-Throw -Because 'BecauseString' -ExceptionMessage 'MockErrorMessage' -ExceptionType ([System.Exception]) -FullyQualifiedErrorId 'MockErrorId' -ScriptBlock {
                            Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
                        }"
                }
            }
        }

        Context 'When the tests are negated' {
            It 'Should convert `Should -Throw` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Not -Throw
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    { Convert-ShouldThrow -CommandAst $mockCommandAstPester5 } | Should-Throw -ExceptionType ([System.Exception]) -ExceptionMessage 'Convert-ShouldThrow should not be called with a negated command. Call Convert-ShouldNotThrow instead.'
                }
            }
        }

        Context 'When tests should always use named parameters' {
            It 'Should convert `Should -Throw ''MockErrorMessage'' ''MockErrorId'' ([System.Exception]) ''BecauseString'' -ActualValue ''ActualString''` correctly' {
                InModuleScope -ScriptBlock {
                    $mockCommandAstPester5 = {
                        Should -Throw 'MockErrorMessage' 'MockErrorId' ([System.Exception]) 'BecauseString' -ActualValue 'ActualString'
                    }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                    $result = Convert-ShouldThrow -CommandAst $mockCommandAstPester5 -UseNamedParameters

                    $result | Should-BeString -CaseSensitive 'Should-Throw -Because ''BecauseString'' -ExceptionMessage ''MockErrorMessage'' -ExceptionType ([System.Exception]) -FullyQualifiedErrorId ''MockErrorId'' -ScriptBlock ''ActualString'''
                }
            }
        }

        Context 'When tests should always use positional parameters' {
            Context 'When the tests are affirming' {
                It 'Should convert `Should -Throw -Because ''BecauseString'' -ActualValue ''ActualString'' -ExceptionType ([System.Exception]) -ErrorId ''MockErrorId'' -ExceptionMessage ''MockErrorMessage''` correctly' {
                    InModuleScope -ScriptBlock {
                        $mockCommandAstPester5 = {
                            Should -Throw -Because 'BecauseString' -ActualValue 'ActualString' -ExceptionType ([System.Exception]) -ErrorId 'MockErrorId' -ExceptionMessage 'MockErrorMessage'
                        }.Ast.Find({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)

                        $result = Convert-ShouldThrow -CommandAst $mockCommandAstPester5 -UsePositionalParameters

                        $result | Should-BeString -CaseSensitive 'Should-Throw ''MockErrorMessage'' ''MockErrorId'' ([System.Exception]) ''BecauseString'' ''ActualString'''
                    }
                }
            }
        }
    }
}
