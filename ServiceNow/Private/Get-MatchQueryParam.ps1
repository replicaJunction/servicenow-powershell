function Get-MatchQueryParam {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Hashtable[]] $Match
    )

    begin {
        function findProp([hashtable] $Hash, [string[]] $PossibleNames) {
            foreach ($name in $possibleNames) {
                if ($hash.ContainsKey($name)) {
                    return $hash[$name]
                }
            }
            return $null
        }

        $queryParts = New-Object -TypeName "System.Collections.Generic.List[String]"
    }

    process {
        foreach ($currentMatch in $Match) {
            # First, find the property, operator, and value
            $prop = findProp -Hash $currentMatch -PossibleNames @('Property', 'prop', 'p')
            $op = findProp -Hash $currentMatch -PossibleNames @('Operator', 'op', 'o')
            $value = findProp -Hash $currentMatch -PossibleNames @('Value', 'val', 'v')


            # If we did not find those, assume the operator is equals (same behavior as MatchExact)
            if (-not $prop -and -not $op -and -not $value) {
                foreach ($k in $currentMatch.Keys) {
                    $currentMatchAdvanced = @{
                        Property = $k
                        Operator = 'eq'
                        Value    = $currentMatch[$k]
                    }
                    $queryFragment = Get-MatchQueryParam $currentMatchAdvanced
                    $queryParts.Add($queryFragment)
                }
                continue
            }

            # Standardize operators
            switch -Regex ($op) {
                'eq(?:ual(?:s)?)?' {
                    $fixedOp = '='
                }
                'GreaterThan|gt' {
                    $fixedOp = '>'
                }
                'LessThan|lt' {
                    $fixedOp = '<'
                }
                'Contains|Like' {
                    $fixedOp = 'LIKE'
                }
                'Between|@' {
                    $fixedOp = 'BETWEEN'
                }
                default {
                    $fixedOp = $op
                }
            }

            if ($fixedOp -eq 'Between') {
                # Special handling for Between operator, which requires two dates
                $dateCount = $value | Measure-Object | Select-Object -ExpandProperty Count
                if ($dateCount -lt 2) {
                    Write-Error "The Between operator requires two dates in the provided value, but only found $dateCount"
                    continue
                }

                $firstDate = Get-QueryDateString $value[0]
                $secondDate = Get-QueryDateString $value[1]

                $fixedValue = '{0}@{1}' -f $firstDate, $secondDate
            }
            elseif ($value -is [DateTime]) {
                # Parse date values
                $fixedValue = Get-QueryDateString $value
            }
            else {
                $fixedValue = $value
            }

            $queryFragment = '{0}{1}{2}' -f $prop, $fixedOp, $fixedValue
            $queryParts.Add($queryFragment)
        }
    }

    end {
        $queryParts.ToArray() -join '^' | Write-Output
    }
}