Write-Host "Cleaning up environment variables."
[System.Environment]::SetEnvironmentVariable('AZURE_TENANT_ID', $null, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_SP_APP_ID', $null, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_SP_APP_SECRET', $null, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_SP_APP_OBJECT_ID', $null, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_SUBSCRIPTION_ID', $null, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_ARM_ENDPOINT', $null, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZURE_LOCATION', $null, [System.EnvironmentVariableTarget]::Machine)