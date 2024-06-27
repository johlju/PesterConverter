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

    # This is not allowed syntax
    # It 'Should be true' {
    #     Should -Be $true $true
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
}
