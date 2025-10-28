#------
#Linux Lite VM Full Build Script for Hyper-VM
#Host: Windows Server 2025 Data Center
#Note: Creation,Configuration, Checkpoints
#Version 1.0
#-------


# ----Variables----
$VMName = "LX01"
$VMPath = "C:\Hyper-V\$VMName"
$VHDPath = "$VMPath\$VMName.vhdx"
$ISOPath = "C:\ISO\LinuxLite\linux-lite-7.6-64bit.iso"

# ---Virtual Switches (must be present in Hyper-V)---

$InternalSwitch1 = "IntSwitch1"


# ---- Create Folder if Missing ---
if (-not (Test-Path $VMPath))
{
    New-Item -Path $VMPath -ItemType Directory | Out-Null
}


# --- Create VM---

Write-Host "Creating Linux Lite (LX01) VM ($VMName)..."
New-VM  -Name $VMName -Generation 2  -MemoryStartupBytes 5GB -SwitchName $InternalSwitch1 -Path $VMPath | Out-Null


# --- Configure CPU, Disk, and Firmware -- 

Set-VMProcessor -VMName $VMName -Count 4 #CPU
New-VHD -Path $VHDPath -SizeBytes 65GB -Dynamic | Out-Null
Add-VMHardDiskDrive -VMName $VMName -Path $VHDPath


# ----Attach pfSense ISO ---

Add-VMDvdDrive -VMName $VMName -Path $ISOPath





# --- Disable Secure Boot No need to include TPM services for Linux ---
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off

# ----- Disable Dynamic Memory For Network Stability ---

Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $false

# ---- Create Pre-Install Checkpoint

Write-Host "Creating pre-install checkpoint..."

Checkpoint-VM -Name $VMName -SnapshotName "Before Linux Lite Installation"


# ----Start the VM
Write-Host "Starting $VMName for Linux Lite installation..."
Start-VM -Name $VMName



# --------------------------------
# ----Post-Install Section (Run After Installation)
# ---------------------------------
<#

# ------Detach ISO so VM boots from disk---

Set-VMDvdDrive -VMName "PF01" -Path $null

# ------Restart VM to Boot pfSense OS---

Restart-VM -Name "LX01"

# -----Wait a few seconds for boot
Start-Sleep -Seconds 10

# ----Create Post-Install Checkpoint

Checkpoint-VM -Name "LX01" -SnapshotName "After Linux Lite Installation"

Write-Host "Linux Lite VM rebooted and post-install checkpoint created."


#>