# Script used to create a VM to use as a build agent.
$VMLocalAdminUser = "VMAdmin"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "!!123abc" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
$LocationName = "bellevue"
$ResourceGroupName = "SDK-sample-agents"
$ComputerName = "windows2016"
$VMName = "windows2016"
$VMSize = "Standard_A3"

$NetworkName = "azurestack-Net"
$NICName = "azurestack-NIC"
$SubnetName = "azurestack-Subnet"
$SubnetAddressPrefix = "10.0.0.0/24"
$VnetAddressPrefix = "10.0.0.0/16"
$availSet = "avail-set-0"
$securityGroupName = "azurestack-nsg"

$SingleSubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = New-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet -Force
$securityGroup = Get-AzNetworkSecurityGroup -Name $securityGroupName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $securityGroup)
{
    $rdpRule = New-AzNetworkSecurityRuleConfig -Name rdp-rule `
        -Description "Allow RDP" `
        -Access Allow `
        -Protocol Tcp `
        -Direction Inbound `
        -Priority 100 `
        -SourceAddressPrefix Internet `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange 3389
    $securityGroup = New-AzNetworkSecurityGroup -Name $securityGroupName -ResourceGroupName $ResourceGroupName -Location $LocationName -SecurityRules $rdpRule
}

$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id -NetworkSecurityGroupId $securityGroup.Id -Force

# Add public IP address with New-AzPublicIpAddress:
$publicIpName = "azurestack-pubip"
$publicIp = New-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $ResourceGroupName -AllocationMethod Static -DomainNameLabel "azurestackazaccount2" -Location $LocationName -Force
$nic = Get-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName
$nic.IpConfigurations[0].PublicIpAddress = $publicIp
Set-AzNetworkInterface -NetworkInterface $nic

<#
New-AzAvailabilitySet -ResourceGroupName "weshi1rg" -Name $availSet -Location northwest
Get-AzVMSize -Location northwest
#> 
New-AzAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $availSet -Location $LocationName -Sku Aligned -PlatformFaultDomainCount 2
$AvailabilitySet = Get-AzAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $availSet 
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize -AvailabilitySetID $AvailabilitySet.Id
#$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $ComputerName -Credential $Credential
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
# Get list of publishers using Get-AzVMImagePublisher
# Get list of offers using Get-AzVMImageOffer
# Get list of skus using Get-AzVMImageSku
#$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '18.04-LTS' -Version latest
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest

New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose