$personalModules = "$HOME\Documents\WindowsPowerShell\Modules"
$modulePath = "$personalModules\TfsWorkItemTools"

Write-Host "Installing TfsSecurityTools module into $modulePath..."

#Remove the module if it is loaded
Get-Module | Where-Object {$_.name -eq "TfsSecurityTools"} | Remove-Module -Force


if((Test-Path $modulePath))
{
	Write-Host "Removing existing module installation at $modulePath..."
	Remove-Item $modulePath -Recurse -Force | Out-Null
}

New-Item -ItemType Directory -Path $modulePath | Out-Null

#copy all items in this package directory except the Install.ps1 script itself
Write-Host "Copying module files"
Get-ChildItem $PSScriptRoot\* -File -Recurse -Exclude Install.ps1 | Copy-Item -Destination $modulePath -Force

Write-Host "Done, press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
