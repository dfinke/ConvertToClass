function Test-String {
    param($p)

    $testResult = $false
    if($p -is [System.ValueType] -Or $p -is [string]) {
        $testResult=$p -is [string]
    }

    [PSCustomObject]@{
        Test=$testResult
        DataType = "string"
    }
}

function Test-Date {
    param($p)

    $testResult = $false
    if($p -is [System.ValueType] -Or $p -is [string]) {
        [datetime]$result  = [datetime]::MinValue
        $testResult=[datetime]::TryParse($p, [ref]$result)
    }

    [PSCustomObject]@{
        Test=$testResult
        DataType = "datetime"
    }
}

function Test-Boolean {
    param($p)

    $testResult = $false
    if($p -is [System.ValueType]) {
        [bool]$result=$false
        $testResult = [bool]::TryParse($p, [ref]$result)
    }

    [PSCustomObject]@{
        Test=$testResult
        DataType = "bool"
    }
}

function Test-Number {
    param($p)

    $testResult = $false
    if($p -is [System.ValueType] -Or $p -is [string]) {
        [double]$result  = [double]::MinValue
        $testResult=[double]::TryParse($p, [ref]$result)
    }

    [PSCustomObject]@{
        Test=$testResult
        DataType = "double"
    }
}

function Test-Integer {
    param($p)

    $testResult = $false
    if($p -is [System.ValueType] -Or $p -is [string]) {
        [int]$result  = [int]::MinValue
        $testResult=[int]::TryParse($p, [ref]$result)
    }

    [PSCustomObject]@{
        Test=$testResult
        DataType = "int"
    }
}

function Test-PSCustomObject {
    param($p)

    $testResult=$p -is [System.Management.Automation.PSCustomObject]

    [PSCustomObject]@{
        Test=$testResult
        DataType = "PSCustomObject"
    }
}

function Test-Array {
    param($p)

    $testResult=$p -is [array]

    [PSCustomObject]@{
        Test=$testResult
        DataType = "Array"
    }
}

$tests = [ordered]@{
    TestBoolean        = Get-Command Test-Boolean
    TestInteger        = Get-Command Test-Integer
    TestNumber         = Get-Command Test-Number
    TestDate           = Get-Command Test-Date
    TestString         = Get-Command Test-String
    TestPSCustomObject = Get-Command Test-PSCustomObject
    TestArray          = Get-Command Test-Array
}

function Invoke-AllTests {
    param(
        $target,
        [Switch]$OnlyPassing,
        [Switch]$FirstOne
    )

    $resultCount=0
    $tests.GetEnumerator() | ForEach {

        $result=& $_.Value $target

        $testResult = [PSCustomObject]@{
            Test     = $_.Key
            Target   = $target
            Result   = $result.Test
            DataType = $result.DataType
        }

        if(!$OnlyPassing) {
            $testResult
        } elseif ($result.Test -eq $true) {
            if($FirstOne) {
                if($resultCount -ne 1) {
                    $testResult
                    $resultCount+=1
                }
            } else {
                $testResult
            }
        }
    }
}

function Get-DataType {
    param($record)

    $p=@($record.psobject.properties.name)

    for ($idx = 0; $idx -lt $p.Count; $idx++) {

        $name = $p[$idx]
        $value = $record.$name

        $result=Invoke-AllTests $value -OnlyPassing -FirstOne

        [PSCustomObject]@{
            Name         = $name
            Value        = $value
            DataType     = $result.DataType
        }
    }
}

function ConvertTo-Class {
    param(
        $className,
        $target
    )

    if($target -is [string]) {
        try {
            $cvt = $target | ConvertFrom-Json

            if(!$className) {
                $className="RootObject"
            }

            ConvertTo-Class $className $cvt
        } catch {

            try {
                $cvt = $target | ConvertFrom-Csv | select -First 1
                if(!$className) {
                    $className="RootObject"
                }

                ConvertTo-Class $className $cvt
            } catch {
                throw "bad data"
            }
        }

        return
    }

    $infered = Get-DataType $target

    $otherClasses=@()

    $xport = switch ($infered) {

        {$_.DataType -eq 'Array'} {

            "`t[{0}[]]`${0}" -f $_.name

            $otherClasses+=ConvertTo-Class $_.name ($_.Value | select -First 1)
        }

        {$_.DataType -eq 'PSCustomObject'} {

            "`t[{0}]`${0}" -f $_.name
            $otherClasses+=ConvertTo-Class $_.name $_.Value
        }

        default {
            "`t[{0}]`${1}" -f $_.DataType, ($_.name -replace "/","")
        }
    }

@"
class $className {
$($xport -join "`r`n")
}

"@

$otherClasses
}
