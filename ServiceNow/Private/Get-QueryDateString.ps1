function Get-QueryDateString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )]
        [DateTime]
        $InputObject
    )

    end {
        $dateStr = "'{0}','{1}'" -f $InputObject.ToString('yyyy-MM-dd'), $InputObject.ToString('HH:mm:ss')
        $queryStr = "javascript:gs.dateGenerate($dateStr)"
        return $queryStr
    }
}