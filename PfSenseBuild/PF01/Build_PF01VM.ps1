#------
#pfSense VM Full Build Script for Hyper-VM
#Host: Windows Server 2025 Data Center
#Note: Creation,Configuration, Checkpoints
#Version 1.0
#-------


# ----Variables----
$VMName = "PF01"
$VMPath = "C:\Hyper-V\$VMName"
$VHDPath = "$VMPath\$VMName.vhdx"
$ISOPath = "C:\ISO\netgate-installer-v1.0-RC-amd64-20240919-1435.iso"

# ---Virtual Switches (must be present in Hyper-V)---

$ExternalSwitch = "ExtSwitch"
$InternalSwitch1 = "IntSwitch1"
$InternalSwitch2 = "IntSwitch2"
$PrivateSwitch = "PrivSwitch"

# ---- Create Folder if Missing ---
if (-not (Test-Path $VMPath))
{
    New-Item -Path $VMPath -ItemType Directory | Out-Null
}


# --- Create VM---

Write-Host "Creating pfSense VM ($VMName)..."
New-VM  -Name $VMName -Generation 2  -MemoryStartupBytes 4GB -SwitchName $ExternalSwitch -Path $VMPath | Out-Null


# --- Configure CPU, Disk, and Firmware -- 

Set-VMProcessor -VMName $VMName -Count 2 #CPU
New-VHD -Path $VHDPath -SizeBytes 20GB -Dynamic | Out-Null
Add-VMHardDiskDrive -VMName $VMName -Path $VHDPath


# ----Attach pfSense ISO ---

Add-VMDvdDrive -VMName $VMName -Path $ISOPath

# ---Add Additional vNICs (LAN+DMZ) ----

Add-VMNetworkAdapter -VMName $VMName -SwitchName $InternalSwitch1 -Name "LAN"
Add-VMNetworkAdapter -VMName $VMName -SwitchName $InternalSwitch2 -Name "DMZ"
Add-VMNetworkAdapter -VMName $VMName -SwitchName $PrivateSwitch -Name "Heartbeat"


# --- Disable Secure Boot (pfSense uses FreeBSD kernel) ---
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off

# ----- Disable Dynamic Memory For Network Stability ---

Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false

# ---- Create Pre-Install Checkpoint

Write-Host "Creating pre-Install checkpoint..."

Checkpoint-VM -Name $VMName -SnapshotName "Before pfSense Installation"


# ----Start the VM
Write-Host "Starting $VMName for pfSense installation..."
Start-VM -Name $VMName


Write-Host "pfSense installer is now running, Complete installation manually in Hyper-V console"
Write-Host "When pfSense says 'Installation complete - Reboot', do NOT reboot yet."
Write-Host "Then run the post-install section below."
Write-Host "-----------------------------------------------------"
Write-Host "Post-install commands are commented out below.  Uncomment them after pfSense installs."
Write-Host "-----------------------------------------------------"

# --------------------------------
# ----Post-Install Section (Run After Installation)
# ---------------------------------
<#

# ------Detach ISO so VM boots from disk---

Set-VMDvdDrive -VMName "PF01" -Path $null

# ------Restart VM to Boot pfSense OS---

Restart-VM -Name "PF01"

# -----Wait a few seconds for boot
Start-Sleep -Seconds 10

# ----Create Post-Install Checkpoint

Checkpoint-VM -Name "PF01" -SnapshotName "After pfSense Installation"

Write-Host "pfSense VM rebooted and post-install checkpoint created."
Write-Host "Access WebGUI from a VM on LAN network at https://192.168.1.1 (default creds: admin /pfsense)"


#>