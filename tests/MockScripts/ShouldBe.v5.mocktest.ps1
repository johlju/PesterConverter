<#
    Tests Pester 5 syntax: Should [[-ActualValue] <Object>] [-Be] [-Not] [-ExpectedValue <Object>] [-Because <Object>]
#>
Describe 'ShouldBe' {
    It 'Should be true' {
        $true | Should -Be $true
    }

    It 'Should be false' {
        $false | Should -Be $false
    }

    It 'Should be true' {
        $true | Should -BeTrue
    }

    It 'Should be false' {
        $false | Should -BeFalse
    }

    It 'Should be true' {
        $false | Should -Not -Be $true
    }

    It 'Should be false' {
        $true | Should -Be $false -Not
    }

    It 'Should be true' {
        $false | Should -Not:$true -BeTrue
    }

    It 'Should be false' {
        $false | Should -Not:$false -BeFalse
    }

    It 'Should be true' {
        Should -ActualValue $true -Be $true
    }

    It 'Should be true' {
        Should -ActualValue $true -BeTrue
    }

    It 'Should be true' {
        Should -Not -ActualValue $true -Be $true
    }

    It 'Should be true' {
        Should -ActualValue $true -BeTrue -Not
    }
}
