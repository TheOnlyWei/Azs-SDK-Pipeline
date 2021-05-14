# Run the SDK samples
Push-Location "${PSScriptRoot}\samples\nodejs\Hybrid-resourcegroups-nodejs-manageresources\"
npm ci
Write-Host "Running index.js"
node "index.js"
Write-Host "Running cleanup.js"
node "cleanup.js"
Pop-Location

