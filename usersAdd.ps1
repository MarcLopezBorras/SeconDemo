### Set path(s):
$AzureDevOpsPAT = Get-Content("credentials.cfg") | ConvertTo-SecureString
$params = Get-Content ("params.txt") | ConvertFrom-StringData
$csv = Import-Csv ("AmadeusAzureUsers.csv")
$uriRestApi = "https://vsaex.dev.azure.com/$($params.OrganizationName)/_apis/"

### Auth Header:
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AzureDevOpsPAT)
$AzureDevOpsPAT = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($AzureDevOpsPAT)")) }

### Get Existing Azure users:
$azureUsers = ""
$Error.Clear()
try
{
    $azureUsers = Invoke-RestMethod -Uri ($uriRestApi + "userentitlements?api-version=6.0-preview.3") -Method get -Headers $AzureDevOpsAuthenicationHeader
}
catch
{
    Write-Host $_.Exception
}
finally
{
    if($Error)
    {
        Write-Host ("Could not retrieve list of existing Azure users.")
    }
}

### Main:
foreach ($line in $csv) 
{ 
        Switch ($line.Action)
        {
#add user to azure
            {$_ -in "a", "ad", "add"}
            {
#region - JSON Body of add user
                $body= @"
{
    "accessLevel": {
    "accountLicenseType": "$($line.'Group rule name')"
  },
  "extensions": [
   {
     "id": "$($line.'Amadeus ID')"
   }
  ],
  "user": {
     "principalName": "$($line.'Amadeus ID')",
     "subjectKind": "user"
  },
  "projectEntitlements": [
   {
     "group": {
     "groupType": "projectContributor"
   },
   "projectRef": {
     "id": "$($params.ProjectID)"
   }
   "TeamRef": {
     "name": "$($line.Team)"
  }
 ]
}
"@
#endregion         

                 $Error.Clear()
                try
                {
                    $response = Invoke-RestMethod -Uri ($uriRestApi + "userentitlements?api-version=6.1-preview.3") -Method get -Headers $AzureDevOpsAuthenicationHeader -Body $body
                }
                catch
                {
                    Write-Host $_.Exception
                }
                finally
                {
                    if(!$Error)
                    {
                        Write-Host ("User: " + $line.'Amadeus ID' + " added.")
                    }
                    else
                    {
                        Write-Host ("Adding user: " + $line.'Amadeus ID' + " failed.")
                    }
                }
                break
            }

#update user in azure
            {$_ -in "md", "mod", "modify"}
            {
                foreach($user in $azureUsers.members)
                {
                    if( $user.user.mailAddress -eq $line.'Amadeus ID')
                    {
#region - JSON Body of modify/update user
                    $body= @"
[
  {
    "from": "",
    "op": "replace",
    "path": "/accessLevel",
    "value": {
      "accountLicenseType": "$($line.'Group rule name')"
    }
  },
  {
    "from": "",
    "op": "replace",
    "path": "/projectRef",
    "value": {
      "id": "$($params.ProjectID)"
    }
  },
    {
    "from": "",
    "op": "replace",
    "path": "/TeamRef",
    "value": {
     "name": "$($line.Team)"
    }
  },
]
"@
#endregion

                         $Error.Clear()
                        try
                        {
                            $response = Invoke-RestMethod -Uri ($uriRestApi + "userentitlements/$($user.id)?api-version=6.1-preview.3") -Method update -Headers $AzureDevOpsAuthenicationHeader -Body $body
                        }
                        catch
                        {
                            Write-Host $_.Exception
                        }
                        finally
                        {
                            if(!$Error)
                            {
                                Write-Host ("User: " + $line.'Amadeus ID' + " modified.")
                            }
                            else
                            {
                                Write-Host ("Modify user: " + $line.'Amadeus ID' + " failed.")
                            }
                        }                     
                        break
                    }
                }
            }

#remove user from azure
            {$_ -in "rm", "rem", "remove"}
            {
                foreach($user in $azureUsers.members)
                {
                    if( $user.user.mailAddress -eq $line.'Amadeus ID')
                    {
                         $Error.Clear()
                        try
                        {
                            $response = Invoke-RestMethod -Uri ($uriRestApi + "userentitlements/$($user.id)api-version=6.1-preview.3") -Method Delete -Headers $AzureDevOpsAuthenicationHeader
                        }
                        catch
                        {
                            Write-Host $_.Exception
                        }
                        finally
                        {
                            if(!$Error)
                            {
                                Write-Host ("User: " + $line.'Amadeus ID' + " removed.")
                            }
                            else
                            {
                                Write-Host ("Removing user: " + $line.'Amadeus ID' + " failed.")
                            }
                        }
                        break
                    }
                }
            }
        }
}