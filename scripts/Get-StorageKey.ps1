$key = (Get-AzStorageAccountKey -ResourceGroupName $(terraformstoragerg) -AccountName $(terraformstorageaccount)).Value[0]

Write-Host "##vso[task.setvariable variable=storagekey]$key"
