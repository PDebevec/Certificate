$ErrorActionPreference = "Stop"
[string]$rootLocation = $PSScriptRoot

Remove-Item -path .\root -Recurse -Force

####################################################################################################
####################                R O O T  C E R T I F I C A T E              ####################
####################################################################################################

New-Item -ItemType Directory -Path .\root\ca
Set-Location .\root\ca
New-Item -ItemType Directory -Path .\certs, .\crl, .\newcerts, .\private
New-Item -ItemType File -Path index.txt
New-Item -ItemType File -Path serial -Value "1000"

Set-Location $rootLocation
Copy-Item -Path .\openssl.root.conf -Destination .\root\ca\openssl.conf -PassThru

Set-Location .\root\ca

Clear-Host
Read-Host "Password for root key" -AsSecureString | ConvertFrom-SecureString | Set-Content -Path .\private\root.pass

openssl genrsa -aes256 -out .\private\ca.key.pem -passout file:".\private\root.pass" 4096
if($LASTEXITCODE) { exit $LASTEXITCODE }

openssl req -config .\openssl.conf -key .\private\ca.key.pem -passin file:".\private\root.pass" -new -x509 -days 3650 -sha256 -extensions v3_ca -out .\certs\ca.cert.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }

Clear-Host
openssl x509 -noout -text -in .\certs\ca.cert.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }
Read-Host "^Verify Root Certificate Information^"

Set-Location $rootLocation

####################################################################################################
####################        I N T E R M E D I A T E  C E R T I F I C A T E      ####################
####################################################################################################

New-Item -ItemType Directory .\root\ca\intermediate
Set-Location -Path .\root\ca\intermediate

New-Item -ItemType Directory -Path .\certs, .\crl, .\csr, .\newcerts, .\private
New-Item -ItemType File -Path .\index.txt
New-Item -ItemType File -Path serial -Value "1000"
New-Item -ItemType File -Path crlnumber -Value "1000"

Set-Location $rootLocation

Copy-Item -Path .\openssl.intermediate.conf -Destination .\root\ca\intermediate\openssl.conf -PassThru

Set-Location .\root\ca\intermediate

Clear-Host
Read-Host "Password for Intermediate key" -AsSecureString | ConvertFrom-SecureString | Set-Content -Path .\private\intermediate.pass
openssl genrsa -aes256 -out .\private\intermediate.key.pem -passout file:".\private\intermediate.pass" 4096
if($LASTEXITCODE) { exit $LASTEXITCODE }

openssl req -config .\openssl.conf -new -sha256 -key .\private\intermediate.key.pem -passin file:".\private\intermediate.pass" -out .\csr\intermediate.csr.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }

Set-Location $rootLocation
Set-Location .\root\ca

openssl ca -config openssl.conf -passin file:".\private\root.pass" -extensions v3_intermediate_ca -days 1825 -notext -md sha256 -in .\intermediate\csr\intermediate.csr.pem -out .\intermediate\certs\intermediate.cert.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }

Clear-Host
openssl x509 -noout -text -in .\intermediate\certs\intermediate.cert.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }
Read-Host "`n^Verify Intermediate Certificate Information^`n"

Clear-Host
openssl verify -CAfile certs\ca.cert.pem intermediate\certs\intermediate.cert.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }
Read-Host

Copy-Item -Path .\intermediate\certs\intermediate.cert.pem -Destination .\intermediate\certs\ca-chain.cert.pem
Get-Content -Path .\certs\ca.cert.pem | Add-Content -Path .\intermediate\certs\ca-chain.cert.pem

Set-Location $rootLocation

####################################################################################################
####################            S E R V E R  C E R T I F I C A T E              ####################
####################################################################################################

Set-Location .\root\ca\intermediate

Clear-Host
Read-Host "Password for Server key" -AsSecureString | ConvertFrom-SecureString | Set-Content -Path .\private\server.pass
openssl genrsa -aes256 -out .\private\server.key.pem -passout file:".\private\server.pass" 4096
if($LASTEXITCODE) { exit $LASTEXITCODE }

openssl req -config .\openssl.conf -key .\private\server.key.pem -passin file:".\private\server.pass" -new -sha256 -out .\csr\server.csr.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }

openssl ca -config .\openssl.conf -extensions server_cert -days 365 -notext -md sha256 -in .\csr\server.csr.pem -passin file:".\private\intermediate.pass" -out .\certs\server.cert.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }

Clear-Host
openssl x509 -noout -text -in .\certs\server.cert.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }
Read-Host "`n^Verify Server Certificate Information^`n"

Clear-Host
openssl verify -CAfile .\certs\ca-chain.cert.pem .\certs\server.cert.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }
Read-Host

Set-Location $rootLocation
Set-Location .\root\ca

Clear-Host
openssl verify -CAfile .\certs\ca.cert.pem -untrusted .\intermediate\certs\intermediate.cert.pem .\intermediate\certs\server.cert.pem
if($LASTEXITCODE) { exit $LASTEXITCODE }

Set-Location $rootLocation