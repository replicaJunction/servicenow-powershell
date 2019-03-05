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
    Describe "Get-QueryDateString" {
        $testCases = @(
            @{
                DateTime = Get-Date '2019-01-01 00:00:00'
            }
            @{
                DateTime = Get-Date '2000-09-08 14:48:27'
            }
        )

        It 'Creates a ServiceNow query date string from the date <DateTime>' -TestCases $testCases {
            param($DateTime)
            $dayStr = Get-Date $DateTime -Format 'yyyy-MM-dd'
            $timeStr = Get-Date $DateTime -Format 'HH:mm:ss'
            Get-QueryDateString $DateTime | Should -BeExactly "javascript:gs.dateGenerate('$dayStr','$timeStr')"
        }
    }
}