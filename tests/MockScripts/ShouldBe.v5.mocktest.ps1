<#
    Tests Pester 5 syntax: Should [[-ActualValue] <Object>] [-Be] [-Not] [-ExpectedValue <Object>] [-Because <Object>]
#>
Describe 'ShouldBe' {
    # It 'Should be true' {
    #     $true | Should -Be $true
    # }

    # It 'Should be false' {
    #     $false | Should -Be $false
    # }

    It 'Should be true' {
        $true | Should -BeTrue
    }

    It 'Should be false' {
        $false | Should -BeFalse
    }

    It 'Should be false' {
        Should -BeFalse 'because mock should test correct value' $false
    }

    It 'Should be false' {
        Should -BeFalse -Because 'because mock should test correct value' $false
    }

    It 'Should be false' {
        Should -BeFalse $false -Because 'because mock should test correct value'
    }

    It 'Should be false' {
        Should -BeFalse -Actual $false 'because mock should test correct value'
    }

    It 'Should be false' {
        Should -BeFalse 'because mock should test correct value' -Actual $false
    }

    # It 'Should be true' {
    #     $false | Should -Not -Be $true
    # }

    # It 'Should be false' {
    #     $true | Should -Be $false -Not
    # }

    # It 'Should be true' {
    #     $false | Should -Not:$true -Be $true
    # }

    It 'Should be true' {
        $false | Should -Not:$true -BeTrue
    }

    It 'Should be false' {
        $false | Should -Not:$false -BeFalse
    }

    # It 'Should be true' {
    #     Should -ActualValue $true -Be $true
    # }

    It 'Should be true' {
        Should -ActualValue $true -BeTrue
    }

    # It 'Should be false' {
    #     Should -Not -ActualValue $true -Be $false
    # }

    # It 'Should be false' {
    #     Should -Be $false -ActualValue $true -Not
    # }

    It 'Should be false' {
        Should -ActualValue $true -BeFalse -Not
    }

    It 'Should be false' {
        Should -ActualValue $true -Be -Not -ExpectedValue $false
    }

    # It 'Should be false' {
    #     Should -ActualValue $true -Be -Not $false
    # }

    # This is not allowed syntax
    # It 'Should be true' {
    #     Should $true -Be $true
    # }

    # This is not allowed syntax
    # It 'Should be true' {
    #     Should $true -BeTrue
    # }

    It 'Should be false' {
        Should -Be $false 'mock should test correct value' $false
    }

    It 'Should be false (with -Because)' {
        Should -Be $false -Because 'mock should test correct value' $false
    }

    It 'Should be false' {
        Should $false 'mock should test correct value' $false -Be
    }

    It 'Should be false' {
        Should -BeExactly 'ExpectedString' 'mock should test correct value' 'ExpectedString'
    }

    It 'Should be false' {
        Should -Be 'ExpectedString' 'mock should test correct value' 'ExpectedString'
    }

    # This is not allowed syntax, it generates an array of values 'a' and 'b' that cannot be compared to a single value
    # It 'Should be false' {
    #     Should -Be @('a', 'b') 'because mock should test correct value' 'a' 'b'
    # }

    It 'Should be true (v6)' {
        Should-Be 'a' 'a'
    }

    It 'Should be true (v6)' {
        Should-Be 'a' 'a' -Because 'a should equal a'
    }

    It 'Should be true (v6)' {
        Should-Be 'a' -Because 'a should equal a' 'a'
    }

    It 'Should be true (v6)' {
        Should-Be -Because 'a should equal a' 'a' 'a'
    }

    It 'Should throw' {
        { throw 'hej' } | Should -Throw
    }

    It 'Should throw' {
        { throw 'hej' } | Should -Throw -Because 'Expected to throw'
    }

    It 'Should throw' {
        { throw 'hej' } | Should -Throw -Because 'Expected to throw' -ErrorId 'hej'
    }

    It 'Should throw' {
        { throw 'hej' } | Should -Throw -Because 'Expected to throw' -ErrorId 'hej' -ExpectedMessage 'hej'
    }

    It 'Should throw' {
        { throw 'hej' } | Should -Throw -Because 'Expected to throw' -ErrorId 'hej' -ExpectedMessage 'hej' -ExceptionType ([Exception])
    }

    It 'Should throw' {
        {
            Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        } | Should -Throw 'MockErrorMessage'
    }

    It 'Should throw' {
        {
            Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        } | Should -Throw 'MockErrorMessage' 'MockErrorId'
    }

    It 'Should throw' {
        {
            Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        } | Should -Throw 'MockErrorMessage' 'MockErrorId' ([System.Exception])
    }

    It 'Should throw' {
        {
            Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        } | Should -Throw 'MockErrorMessage' 'MockErrorId' ([System.Exception]) 'BecauseString'
    }


    # It 'Should throw' {
    #     { 1+1 } | Should -Throw -Because 'Expected to throw' -ErrorId 'hej' -ExpectedMessage 'hej' -ExceptionType ([Exception]) -Not
    # }

    It 'Should throw' {
        $errorPassThru = ({ throw 'hej' } | Should -Throw -Because 'Expected to throw' -ErrorId 'hej' -ExpectedMessage 'hej' -ExceptionType ([Exception]) -PassThru)
        $errorPassThru.Exception.Message | Should -Be 'hej'
    }

    It 'Should throw' {
        { throw 'hej' } | Should -Throw 'hej'
    }

    It 'Should throw with actual value' {
         Should -Throw 'hej' -ActualValue { throw 'hej' }
    }

    It 'Should throw using only positional parameters' {
        {
            Write-Error -Message 'MockErrorMessage' -ErrorId 'MockErrorId' -Category 'InvalidOperation' -TargetObject 'MockTargetObject' -ErrorAction 'Stop'
        } | Should -Throw 'MockErrorMessage' 'MockErrorId' ([Microsoft.PowerShell.Commands.WriteErrorException]) 'MockBecauseString'
    }

    # Not possible without curly braces (script block)
    # It 'Should throw using only named parameters' {
    #     (1 + 1) | Should -Not -Throw -ExpectedMessage 'MockErrorMessage' -ErrorId 'MockErrorId' -ExceptionType ([Microsoft.PowerShell.Commands.WriteErrorException]) -Because 'MockBecauseString'
    # }

    # Not supported in Pester 5
    # It 'Should BeOfType' {
    #     Should [System.String] $null 'ActualValue' -BeOfType
    # }

    # Not supported in Pester 5
    # It 'Should BeOfType' {
    #     Should [System.String] 'ActualValue' 'mock must have correct type' -BeOfType
    # }

    It 'Should BeOfType' {
        Should [System.String] 'mock must have correct type' -ActualValue 'ActualValue' -BeOfType
    }

    It 'Should BeOfType' {
        'ActualValue' | Should [System.String] 'mock must have correct type' -BeOfType
    }

}
