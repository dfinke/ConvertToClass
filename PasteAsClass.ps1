$sb  = {

    $newFile = $psISE.CurrentPowerShellTab.Files.Add()

    $srcText = (Get-Clipboard) -join "`n"

    $newFile.Editor.Text=((ConvertTo-Class $srcText) -join "`r`n")

    Clear-Host
}

$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Paste as PowerShell Class", $sb, "ctrl+shift+v")