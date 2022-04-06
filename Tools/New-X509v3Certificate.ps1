#           _          _       
#        __| |____ ___| |__    
#       / _  |__  / __| '_ \           
#      | (_| |(_| \__ \ | | |
#       \__,_\__,_|___/_| |_(_)
#       T  R  A  I  N  I  N  G 

#          Script: 'New-X509v3Certificate.ps1'

# Original author: Adam Conkle - Microsoft Corporation 
# Original source: http://social.technet.microsoft.com/wiki/contents/articles/4714.how-to-generate-a-self-signed-certificate-using-powershell.aspx

# Adopted by:      Paul Wojcicki-Jarocki - Paul Dash (paul@pauldash.com)
# Adopted because: * 
#                  * commented throughout
#                  * change to more secure sha256
#                  * certificate validity period is corrected
#                  * generated certificate is added to correct stores


Write-Host    "This script will generate a self-signed certificates with exportable private key.`n"

$ContextAnswer = Read-Host "Store certificate in the User or Computer store? (U/C)"
if ($ContextAnswer -eq "U") { 
    $machineContext    = 0 
    $initContext       = 1
    $CertStoreLocation = 'CurrentUser' 
} elseif ($ContextAnswer -eq "C") { 
    $machineContext    = 1 
    $initContext       = 2
    $CertStoreLocation = 'LocalMachine'
} else { 
    Write-Host "Invalid selection. Exiting."
    Exit 
}

# Set certificate Subject name based on user input
$Subject = Read-Host "Subject of the certificate  "

# Dangerous things about to happen ;)
$ErrorActionPreference = 'Stop'

if (Get-ChildItem "Cert:\$CertStoreLocation\My\" | Where-Object {$_.Subject -eq "CN=$Subject"}) {
    Write-Warning "Other certificates for that subject exist."
}

$DistinguishedName = New-Object -ComObject "X509Enrollment.CX500DistinguishedName.1"  
$DistinguishedName.Encode("CN=$Subject", 0)

# Generate private key
$key = New-Object -ComObject 'X509Enrollment.CX509PrivateKey.1'
$key.ProviderName = 'Microsoft RSA SChannel Cryptographic Provider'
#$key.ProviderName = 'Microsoft Base Smart Card Crypto Provider' # from CryptoAPI
#$key.ProviderName = 'Microsoft Smart Card Key Storage Provider' # from CNG 
$key.KeySpec = 1 # for other purposes: 3
$key.Length = 2048 
$key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"  
$key.MachineContext = $machineContext 
$key.ExportPolicy = 1 # 0 for non-exportable Private Key
$key.Create()

# Create OID for intended usage
### TODO: check out the .NET type System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension
$codesigningoid = New-Object -ComObject 'X509Enrollment.CObjectId.1'
### TODO: put this in a SWITCH
$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.3")        # Code Signing
#$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")       # Server Authentication
#$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.2")       # Client Authentication
#$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.4")       # Secure Email
#$codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.8")       # Time Stamping
#$codesigningoid.InitializeFromValue("1.3.6.1.4.1.311.10.3.12") # Document Signing

# Add OID to list
$ekuoids = New-Object -ComObject "X509Enrollment.CObjectIds.1"
$ekuoids.Add($codesigningoid)


##################
<#
# Add OID to list
$ekuoids = New-Object -ComObject "X509Enrollment.CObjectIds.1"

@'
Code Signing
Server Authentication
Client Authentication
Secure Email
Time Stamping
Document Signing
'@
$ExitSelectingOID = $false
do {
    $ekuOID = New-Object -ComObject "X509Enrollment.CObjectId.1"
    
    switch (Read-Host -Prompt 'Type choice of Enhanced Key Usage or [D]one')
    {
        '1' { $ekuOID.InitializeFromValue("1.3.6.1.5.5.7.3.3") }
        '2' { $ekuOID.InitializeFromValue("1.3.6.1.5.5.7.3.1") }
        '3' { $ekuOID.InitializeFromValue("1.3.6.1.5.5.7.3.2") }
        '4' { $ekuOID.InitializeFromValue("1.3.6.1.5.5.7.3.4") }
        '5' { $ekuOID.InitializeFromValue("1.3.6.1.5.5.7.3.8") }
        '6' { $ekuOID.InitializeFromValue("1.3.6.1.4.1.311.10.3.12") }
        'D' { $ExitSelectingOID = $true }
        Default { 'Unsupported key usage!' }
    }

    if ($ekuOID.Value -and ($ekuOID -notin $ekuoids)) {
        $ekuoids.Add($ekuOID)
    }

} until ($ExitSelectingOID)
#>



# Add list of OIDs to extensions
$ekuext = New-Object -ComObject 'X509Enrollment.CX509ExtensionEnhancedKeyUsage.1'
$ekuext.InitializeEncode($ekuoids) 

# Create certificate request
$CertReq = New-Object -ComObject 'X509Enrollment.CX509CertificateRequestCertificate.1'
$CertReq.InitializeFromPrivateKey($initContext, $key, "")
### $CertReq.CriticalExtensions.Remove(0) # Remove 'Key Usage'
$CertReq.Subject = $DistinguishedName
### $CertReq.Issuer = $CertReq.Subject # Self-signed, so Issuer generated automatically
$CertReq.NotBefore = (Get-Date).ToUniversalTime().Date
$CertReq.NotAfter = $CertReq.NotBefore.AddYears(1)

# Set signing algorithm to SHA-2 256-bit
[string]$SigAlgorithmName = 'sha256'
$SigAlgorithmOID = New-Object -ComObject X509Enrollment.CObjectId
$SigAlgorithmOID.InitializeFromValue(([Security.Cryptography.Oid]$SigAlgorithmName).Value)
$CertReq.HashAlgorithm = $SigAlgorithmOID

# Add list of extensions to request
$CertReq.X509Extensions.Add($ekuext)

# Generate request
$CertReq.Encode()

# Send request
$Enrollment = New-Object -ComObject 'X509Enrollment.CX509Enrollment.1'
$Enrollment.InitializeFromRequest($CertReq)
# Receive requested certificate in DER-encoded format
$CertBASE64 = $Enrollment.CreateRequest(0)

Write-Host "Certificate creation: $($Enrollment.Status.ErrorText)" -ForegroundColor Green

# Install certificate in store
# https://docs.microsoft.com/en-us/windows/win32/api/certenroll/nf-certenroll-ix509enrollment-installresponse
# Restrictions = 4 (AllowUntrustedRoot)
# Encoding     = 0 (XCN_CRYPT_STRING_BASE64HEADER)
$Enrollment.InstallResponse(4, $CertBASE64, 0, "")

# Export certificate to a file
$FilePath = Read-Host "Directory path to store the .CER file"
if (Test-Path -Path $FilePath -PathType Container) {
    # Encoding = 12 (XCN_CRYPT_STRING_HEXRAW)
    $SignedCert = Get-ChildItem "Cert:\$CertStoreLocation\My\" |
                  Where-Object {$_.SerialNumber -eq $CertReq.SerialNumber(12).Trim()}
    $ExportedCertPath = Export-Certificate -Cert $SignedCert -FilePath (Join-Path -Path $FilePath -ChildPath "$Subject.cer")
} else {
    Write-Warning "Certificate export:   Could not write to path $FilePath. Will not save to the CA and publishers stores."
    exit
}
# Verify export
if (Test-Path -Path $ExportedCertPath -PathType Leaf) {
    Write-Host "Certificate export:   Completed successfully." -ForegroundColor Green
} else {
    Write-Warning "Certificate export:   File export failed. Will not save to the CA and publishers stores."
    exit
}

if ($SignedCert.EnhancedKeyUsageList.FriendlyName -contains 'Code Signing') {

    # Import certificate into Root CA (or Intermediate Certification Authorities) and Trusted Publishers
    Import-Certificate -FilePath $ExportedCertPath -CertStoreLocation "Cert:\$CertStoreLocation\Root" | Out-Null
    Import-Certificate -FilePath $ExportedCertPath -CertStoreLocation "Cert:\$CertStoreLocation\TrustedPublisher" | Out-Null
    # Verify import
    if ((Get-ChildItem "Cert:\$CertStoreLocation\Root\$($SignedCert.Thumbprint)") -and
        (Get-ChildItem "Cert:\$CertStoreLocation\TrustedPublisher\$($SignedCert.Thumbprint)")) {
            Write-Host "Certificate install:  Completed successfully." -Fore Green
    }

    Write-Host "`nUse this path for Set-AuthenticodeSignature:`nCert:\$CertStoreLocation\My\$($SignedCert.Thumbprint)"
}
