#
To use the script, prepare your 'credentials.cfg' first:

```
$plainPassword = 'pat'
$securePassword = $plainPassword | ConvertTo-SecureString -AsPlainText -Force
$secureStringText = $securePassword | ConvertFrom-SecureString
Set-Content "credentials.cfg" $secureStringText
```