# Changelog for PesterConverter

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Public commands:
  - `Convert-PesterSyntax`
    - Add support for `Should` operators:
      - Be
      - BeExactly
      - BeFalse
      - BeGreaterOrEqual
      - BeGreaterThan
      - BeIn
      - BeLessOrEqual
      - BeLessThan
      - BeLike
      - BeLikeExactly
      - BeNullOrEmpty
      - BeOfType
      - BeTrue
      - Contain
      - HaveCount
      - Invoke
      - Match
      - MatchExactly
      - Throw
    - Add support for `Assert-MockCalled`.
    - Added new parameter `OutputPath` to write the resulting file to
      a separate path.
- Add integration tests.

### Fixed

- Improve code to resolve ScriptAnalyzer warnings and errors.
- Localize all the strings.
- `Convert-PesterSyntax`
  - The `Should` operators `BeLike` and `BeLikeExactly` was mistakenly not
    calling their respectively conversion function.
  - Correctly handle abbreviated named parameters.
- `Should -BeFalse`, `Should -BeTrue` and `Should -BeNullOrEmpty` are now
  correctly converted when `Because` is the only positional parameter.
- Negated `Should -Not -BeLessThan` now converts to `Should-BeGreaterThanOrEqual`
  to correctly handle scenario when actual value and expected value are the same.
- Negated `Should -Not -BeGreaterThan` now converts to `Should-BeLessThanOrEqual`
  to correctly handle scenario when actual value and expected value are the same.
- Fix parameter name in `Convert-ShouldBeOfType`
- Minor change to `Get-AstDefinition` to handle when a file is not correctly
  parsed.
- Some code cleanup.
- Fix incorrect position value in Get-PesterCommandParameter.
- Update PowerShell version requirement to 7.1.
- `Get-PesterCommandParameter`
  - Now supports Switch parameters.
  - Also supports when Switch parameters is the last parameter on the extent.
- Update test assertions to use Pester v6 syntax.
- Updated conversion documentation for `Should -Invoke`, `Should -Not -Invoke`
  and `Should -HaveCount`.
- Now converting `Should -HaveCount` works when `-Not:$false` is specified.
- Bump action Stale to v10
- Bump action Checkout to v7
- Bump action codeql-action/upload-sarif to v4
- Improve the warning message when user have user short form of a parameter name.
