# build_trust_bundle.ps1

param (
    [string]$TenantId = $env:AEMBIT_TENANT_ID
)

if (-not $TenantId) {
    Write-Error "Tenant ID not provided. Set the AEMBIT_TENANT_ID environment variable or pass -TenantId."
}

# Create build directory
$buildDir = "build"
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Download Python Requests certificate bundle
$certifiUrl = "https://raw.githubusercontent.com/certifi/python-certifi/master/certifi/cacert.pem"
$certFile = "$buildDir\cacert.pem"
Invoke-WebRequest -Uri $certifiUrl -OutFile $certFile -UseBasicParsing

# Download Tenant Root CA and append to cacert.pem
$rootCaUrl = "https://${TenantId}.aembit.io/api/v1/root-ca"
$rootCaTempFile = "$buildDir\root-ca.pem"
Invoke-WebRequest -Uri $rootCaUrl -OutFile $rootCaTempFile -UseBasicParsing
Get-Content $rootCaTempFile | Add-Content $certFile
Remove-Item $rootCaTempFile

# Zip the trust bundle
$zipPath = "$buildDir\trustbundle.zip"
Compress-Archive -Path $certFile -DestinationPath $zipPath -Force

# Clean up
Remove-Item $certFile

Write-Output "Trust bundle created: $zipPath"