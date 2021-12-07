# Specify vault settings
$VaultName = "VaultName"
$SecretName = "Secretname"

# Convert encrypted token to SecureString
$SecurePersonalAccessToken = (Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName).SecretValue

# Read Azure DevOps parameters from a text file
Get-Content -Path .\params.txt -ReadCount 2 | ForEach-Object {
    $SplattedParameters = ConvertFrom-StringData $($_ -join [Environment]::NewLine)
}

# Unnecessary step just to save time
$OrganizationName = $SplattedParameters.OrganizationName
$ProjectName = $SplattedParameters.ProjectName

# Convert SecureString to plaintext
$BSTR = `
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePersonalAccessToken)
$PlainPersonalAccessToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Define authentication method
$BasicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f '', $PlainPersonalAccessToken)))

# Create authorization header
$AuthorizationHeader = @{
    Authorization = "Basic $BasicAuth"
}

# Create request body
$Area = @{
    name = "Another area name2"
    }

# Convert request body to JSON
$JsonBody = $Area | ConvertTo-Json

# Submit POST request to Azure DevOps API to create the area
$Area = Invoke-RestMethod -Method POST `
    -Uri $OrganizationName/$ProjectName/_apis/wit/classificationnodes/Areas?api-version=6.0 `
    -ContentType "application/json" `
    -Headers $AuthorizationHeader `
    -body $JsonBody