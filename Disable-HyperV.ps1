#Requires -RunAsAdministrator

$features = @(
    "Microsoft-Hyper-V"
    "VirtualMachinePlatform"
)

foreach ($feature in $features) {
    $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
    if ($state -ne "Disabled") {
        Write-Host "Disabling $feature..."
        Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
    } else {
        Write-Host "$feature is already disabled."
    }
}

# Stop and disable Hyper-V services
$services = @(
    @{Name = "vmms"; Display = "Hyper-V Virtual Machine Management"},
    @{Name = "vmicheartbeat"; Display = "Hyper-V Heartbeat Service"},
    @{Name = "vmickvpexchange"; Display = "Hyper-V Data Exchange Service"},
    @{Name = "vmicrdv"; Display = "Hyper-V Remote Desktop Virtualization"},
    @{Name = "vmicshutdown"; Display = "Hyper-V Guest Shutdown Service"},
    @{Name = "vmictimesync"; Display = "Hyper-V Time Synchronization Service"},
    @{Name = "vmicvss"; Display = "Hyper-V Volume Shadow Copy Requestor"}
)

foreach ($svc in $services) {
    $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($s) {
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc.Name -StartupType Disabled
        Write-Host "$($svc.Display) stopped and disabled."
    }
}

Write-Host "`nAll Hyper-V and Virtual Machine Platform features disabled."
Write-Host "A system restart is recommended for the changes to take effect." -ForegroundColor Yellow
