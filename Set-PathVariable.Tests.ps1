BeforeAll {
    . "$PSScriptRoot\Set-PathVariableHelpers.ps1"
}

Describe "Build-NewPath" {

    Context "Normal path concatenation" {

        It "appends new location separated by a semicolon" {
            $result = Build-NewPath -OldPath "C:\foo;C:\bar" -NewLocation "C:\baz"
            $result | Should -Be "C:\foo;C:\bar;C:\baz"
        }

        It "returns only the new location when old path is empty" {
            $result = Build-NewPath -OldPath "" -NewLocation "C:\baz"
            $result | Should -Be "C:\baz"
        }
    }

    Context "Trailing semicolon handling" {

        It "does not produce a double semicolon when old path ends with a semicolon" {
            $result = Build-NewPath -OldPath "C:\foo;C:\bar;" -NewLocation "C:\baz"
            $result | Should -Not -Match ";;"
        }

        It "correctly joins entries when old path ends with a semicolon" {
            # Regression test: previously ';;' was replaced with '' which caused
            # two path entries to be concatenated without any separator.
            $result = Build-NewPath -OldPath "C:\foo;C:\bar;" -NewLocation "C:\baz"
            $result | Should -Be "C:\foo;C:\bar;C:\baz"
        }
    }
}
