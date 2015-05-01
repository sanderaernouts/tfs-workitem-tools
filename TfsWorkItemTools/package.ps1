Try{
	$packageDir = "$PSScriptRoot\bin\Debug\published packages"
    $packagingDir = "$packageDir\TfsWorkItemTools"


    if(Test-Path $packageDir)
    {
        Remove-Item $packageDir -Force -Recurse | Out-Null
    }

	New-Item -ItemType Directory $packageDir | Out-Null
    New-Item -ItemType Directory $packagingDir | Out-Null
    
    #gather files in the module TfsSecurityTools folder
    Copy-Item $PSScriptRoot\TfsWorkItemTools.psd1 -Destination $packagingDir
	Copy-Item $PSScriptRoot\TfsWorkItemTools.psm1 -Destination $packagingDir
	Copy-Item $PSScriptRoot\install.ps1 -Destination $packagingDir

	#create a zip package
	$zipFile = "$packageDir\TfsWorkItemTools.zip"
	if(Test-Path "$PSScriptRoot\..\TfsSecurityTools.zip")
	{
		Get-ChildItem -File $zipFile | Remove-Item
	}
	Add-Type -Assembly System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory($packagingDir,$zipFile, $compressionLevel, $false)

    #open the package directory
    explorer $packageDir
}
Catch [system.exception] {
    Write-Error $_
	#force the build to fail on post build script error
    exit 1
}