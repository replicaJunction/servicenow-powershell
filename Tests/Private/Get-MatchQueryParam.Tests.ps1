$ProjectRoot = Resolve-Path "$PSScriptRoot\..\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psd1")
$ModuleName = Split-Path $ModuleRoot -Leaf
$ModulePsd = (Resolve-Path "$ProjectRoot\*\$ModuleName.psd1").Path
$ModulePsm = (Resolve-Path "$ProjectRoot\*\$ModuleName.psm1").Path

$ModuleLoaded = Get-Module $ModuleName
if ($null -eq $ModuleLoaded) {
    Import-Module $ModulePSD -Force
}
elseif ($null -ne $ModuleLoaded -and $ModuleLoaded -ne $ModulePSM) {
    Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    Import-Module $ModulePSD -Force
}

InModuleScope "$ModuleName" {
    Describe "Get-MatchQueryParam" -Tag @('Unit', 'Private') {
        #region Hashtable syntax tests
        $paramTestCases = @(
            @{
                PropertyKeyName = 'Property'
                OperatorKeyName = 'Operator'
                ValueKeyName    = 'Value'
            }
            @{
                PropertyKeyName = 'Prop'
                OperatorKeyName = 'Op'
                ValueKeyName    = 'Val'
            }
            @{
                PropertyKeyName = 'p'
                OperatorKeyName = 'o'
                ValueKeyName    = 'v'
            }
        )

        It 'Handles an input hashtable with keys <PropertyKeyName>, <OperatorKeyName>, and <ValueKeyName>' -TestCases $paramTestCases {
            param($PropertyKeyName, $OperatorKeyName, $ValueKeyName)

            $hash = @{}
            $hash[$PropertyKeyName] = 'sys_id'
            $hash[$OperatorKeyName] = 'eq'
            $hash[$ValueKeyName] = 12345

            Get-MatchQueryParam -Match $hash | Should -BeExactly 'sys_id=12345'
        }
        #endregion

        #region Operator tests
        $operatorTestCases = @(
            @{
                Variant  = 'Equals'
                Expected = '='
            }
            @{
                Variant  = 'equal'
                Expected = '='
            }
            @{
                Variant  = 'eq'
                Expected = '='
            }
            @{
                Variant  = '='
                Expected = '='
            }
            @{
                Variant  = 'GreaterThan'
                Expected = '>'
            }
            @{
                Variant  = 'gt'
                Expected = '>'
            }
            @{
                Variant  = '>'
                Expected = '>'
            }
            @{
                Variant  = 'LessThan'
                Expected = '<'
            }
            @{
                Variant  = 'lt'
                Expected = '<'
            }
            @{
                Variant  = '<'
                Expected = '<'
            }
            @{
                Variant  = 'Contains'
                Expected = 'LIKE'
            }
            @{
                Variant  = 'Like'
                Expected = 'LIKE'
            }
        )

        It "Operator value [<Variant>] correctly translates to [<Expected>]" -TestCases $operatorTestCases {
            param($Name, $Variant, $Expected)
            $hash = @{
                Property = 'sys_id'
                Operator = $Variant
                Value    = '12345'
            }

            Get-MatchQueryParam -Match $hash | Should -BeExactly "sys_id${Expected}12345"
        }
        #endregion

        It 'If a hashtable is provided that does not match the advanced syntax, it treats it as a series of key=value pairs' {
            $hash = @{
                'sys_created_by' = 'username'
                'sys_id'         = '12345'
            }

            # The hashtable .Keys property sorts string keys, so even in an unordered hashtable,
            # the keys should appear in alphabetical order in the query.

            Get-MatchQueryParam -Match $hash | Should -BeExactly "sys_created_by=username^sys_id=12345"
        }

        # We're not testing this helper function here, so we don't care if this matches the format
        # ServiceNow expects. We just want to make sure it matches the output of this mock.
        Mock Get-QueryDateString { Get-Date $InputObject -Format 'yyyyMMdd' }

        It 'Translates a date using the Get-QueryDateString helper function' {
            $hash = @{
                Property = 'sys_created_on'
                Operator = 'eq'
                Value    = Get-Date '2019-01-01 00:00:00'
            }

            Get-MatchQueryParam -Match $hash | Should -BeExactly 'sys_created_on=20190101'
            Assert-MockCalled Get-QueryDateString -ParameterFilter {$InputObject -eq (Get-Date '2019-01-01 00:00:00')} -Scope It -Exactly -Times 1
        }

        It 'Supports multiple date values with the BETWEEN operator' {
            $hash = @{
                Property = 'sys_created_on'
                Operator = 'Between'
                Value    = @(
                    Get-Date '2019-01-01 00:00:00'
                    Get-Date '2019-01-31 23:59:59'
                )
            }

            # Again, the dates will match our mock of the helper method, not the ServiceNow format
            Get-MatchQueryParam -Match $hash | Should -BeExactly 'sys_created_onBETWEEN20190101@20190131'
        }
    }
}