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
        Should -Be $false 'because mock should test correct value' $false
    }

    It 'Should be false' {
        Should -BeExactly 'AnyString' 'because mock should test correct value' 'AnyString'
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
        { 1+1 } | Should -Throw -Because 'Expected to throw' -ErrorId 'hej' -ExpectedMessage 'hej' -ExceptionType ([Exception]) -Not
    }

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

    It 'Should throw' {
        {
            Write-Error -Message 'hej' -ErrorId 'MyErrorId' -Category InvalidOperation -TargetObject 'MyTargetObject' -ErrorAction 'Stop'
        } | Should -Throw 'hej' 'MyErrorId' ([Microsoft.PowerShell.Commands.WriteErrorException]) 'the mock error should throw correct error'
    }

}
