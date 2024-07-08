Describe 'Pester6 Syntax' {
    Context 'Should-Throw' {
        # This is not possible in Pester 6 syntax due to ActualValue is first positional parameter.
        # It 'Test Should-Throw positional parameters' {
        #     {
        #             Write-Error -Message 'hej' -ErrorId 'MyErrorId' -Category 'InvalidOperation' -TargetObject 'MyTargetObject' -ErrorAction 'Stop'
        #     } | Should-Throw ([Microsoft.PowerShell.Commands.WriteErrorException]) 'hej' 'MyErrorId'
        #     # Should -Throw 'hej' 'MyErrorId' ([Microsoft.PowerShell.Commands.WriteErrorException]) 'the mock error should throw correct error'
        # }

        It 'Test Should-Throw with named parameters' {
            {
                    Write-Error -Message 'hej' -ErrorId 'MyErrorId' -Category 'InvalidOperation' -TargetObject 'MyTargetObject' -ErrorAction 'Stop'
            } | Should-Throw -ExceptionType ([Microsoft.PowerShell.Commands.WriteErrorException]) -ExceptionMessage 'hej' -FullyQualifiedErrorId 'MyErrorId'
        }

        It 'Test Should-Throw with positional parameters' {
            $mockScript = {
                    Write-Error -Message 'hej' -ErrorId 'MyErrorId' -Category 'InvalidOperation' -TargetObject 'MyTargetObject' -ErrorAction 'Stop'
            }

            Should-Throw $mockScript ([Microsoft.PowerShell.Commands.WriteErrorException]) 'hej' 'MyErrorId'
        }

        # Not currently supported in Pester 6 syntax due to ScriptBlock being first positional parameter.
        # It 'Should throw when using pipeline input and the usage of positional parameters' {
        #     {
        #         Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        #     } | Should-Throw ([Microsoft.PowerShell.Commands.WriteErrorException]) 'MockErrorMessage' 'MockErrorId' 'MockBecauseString'
        # }

        It 'Should throw when using only positional parameters' {
            Should-Throw {
                Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
            } ([Microsoft.PowerShell.Commands.WriteErrorException]) 'MockErrorMessage' 'MockErrorId' 'MockBecauseString'
        }

        # This is not possible in Pester 6 syntax due to ScriptBlock being first positional parameter.
        # It 'Should throw when using only one positional parameters' {
        #     {
        #         Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        #     } | Should-Throw 'MockErrorMessage'
        # }

        It 'Should not throw, passing to ForEach-Object' {
            {
                Write-Verbose -Message 'Some message'
                #Get-Something
                #Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
            } | ForEach-Object -Process { & $_ } | Out-Null
        }

        It 'Should not throw, calling Ast.GetScriptBlock().Invoke()' {
            {
                Write-Verbose -Message 'Some message'
                #Get-Something
                #Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
            }.Ast.GetScriptBlock().Invoke()
        }

        It 'Should not throw, without any scriptblock' {
            Write-Verbose -Message 'Some message'
            #Get-Something
            #Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        }

        It 'Should not throw, call scriptblock in variable' {
            $scriptBlock = {
                Write-Verbose -Message 'Some message'
                #Get-Something
                #Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
            }

            # Should use parenthesis
            $null = & $scriptBlock
        }

        # Not possible in Pester 6 syntax
        # It 'Should not throw, call two scriptblock assigned to variables' {
        #     $scriptBlock1 = {
        #         Write-Verbose -Message 'Some message' -Verbose
        #         #Get-Something
        #         #Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        #     }

        #     $scriptBlock2 = {
        #         Write-Verbose -Message 'Some message' -Verbose
        #         #Get-Something
        #         #Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        #     }

        #     # Must use parenthesis
        #     & (($scriptBlock1), ($scriptBlock2))
        # }

        It 'Should not throw, call scriptblock within parenthesis using call operator' {
            $null = & ({
                Write-Verbose -Message 'Some message'
                #Get-Something
                #Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
            })
        }

        It 'Should not throw, call scriptblock using call operator' {
            $null = & {
                Write-Verbose -Message 'Some message'
                #Get-Something
                #Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
            }
        }
    }

    Context 'Should-Be' {
        It 'Test Should-Be with named parameters' {
            Should-Be 'a' -Expected 'a' -Because 'a should equal a'
        }

        # This is not supported
        # It 'Test Should-Be with positional parameters' {
        #     Should-Be 'a' 'a' 'a should equal a'
        # }

        It 'Test Should-Be with both named and positional parameters' {
            Should-Be $false -Because 'mock should test correct value' $false
        }

        It 'Test `Should-Be -Actual $true $true` works' {
            Should-Be -Actual $true $true
        }
    }

    Context 'Should-BeString' {
        It 'Test Should-BeString with named parameters' {
            Should-BeString 'a' -Expected 'a' -Because 'a should equal a'
        }

        # This is not supported
        # It 'Test Should-BeString with positional parameters' {
        #     Should-BeString 'a' 'a' 'a should equal a'
        # }

        It 'Test Should-BeString with both named and positional parameters' {
            Should-BeString -CaseSensitive 'AnyString' -Because 'mock should test correct value' 'AnyString'
        }
    }


    Context 'Should-BeTrue' {
        It 'Test Should-BeTrue with named parameters' {
            Should-BeTrue -Actual $true -Because 'true should be true'
        }

        It 'Test Should-BeTrue with positional parameters' {
            Should-BeTrue $true 'true should be true'
        }
    }

    Context 'Should-HaveType' {
        It 'Test Should-HaveType with named parameters' {
            Should-HaveType -Actual 'a' -Expected 'System.String' -Because 'a should be of type System.String'
        }

        It 'Test Should-HaveType with positional parameters' {
            Should-HaveType 'System.String' 'a' -Because 'a should be of type System.String'
        }

        It 'Test Should-HaveType with pipeline input' {
            'a' | Should-HaveType 'System.String' -Because 'a should be of type System.String'
        }

        It 'Test Should-HaveType with  input' {
            'a' | Should-HaveType ([System.String]) -Because 'a should be of type System.String'
        }

        # This is not supported
        # It 'Test Should-HaveType with pipeline input' {
        #     'a' | Should-HaveType [System.String] -Because 'a should be of type System.String'
        # }
    }

    Context 'v5 Should -Contain' {
        It 'Should contain a specific string, using named parameters' {
            'A','b','c' | Should-Any -FilterScript { $_ | Should-Be -Expected 'a' }
        }

        It 'Should contain a specific string, using positional parameters' {
            'A','b','c' | Should-Any { $_ | Should-Be 'a' }
        }
    }

    Context 'Should-ContainCollection' {
        It 'Test Should-ContainCollection with named parameters' {
            Should-ContainCollection -Actual @('a', 'b', 'c') -Expected 'a' -Because 'a should be in the collection'
        }

        It 'Test Should-ContainCollection with positional parameters' {
            Should-ContainCollection 'a' @('a', 'b', 'c') -Because 'a should be in the collection'
        }

        It 'Test Should-ContainCollection with pipeline input' {
            @('a', 'b', 'c') | Should-ContainCollection 'a' -Because 'a should be in the collection'
        }
    }
}
