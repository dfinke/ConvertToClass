Set-PSReadlineKeyHandler -Key Ctrl+Shift+V `
    -BriefDescription PasteAsClass `
    -LongDescription 'Paste text on clipboard as a PowerShell class' `
    -ScriptBlock { 
        param($key, $arg)
        
        $newClass=(ConvertTo-Class ((Get-Clipboard) -join "`n"))
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($newClass -join "`n"))
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}