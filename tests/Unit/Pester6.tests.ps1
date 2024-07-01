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
}
