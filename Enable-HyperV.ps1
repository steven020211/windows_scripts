#Requires -RunAsAdministrator

$features = @(
    "Microsoft-Hyper-V"
    "VirtualMachinePlatform"
)

foreach ($feature in $features) {
    $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
    if ($state -ne "Enabled") {
        Write-Host "Enabling $feature..."
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
    } else {
        Write-Host "$feature is already enabled."
    }
}

# Ensure Hyper-V services start automatically and are running
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
        Set-Service -Name $svc.Name -StartupType Automatic
        if ($s.Status -ne "Running") {
            Start-Service -Name $svc.Name
        }
        Write-Host "$($svc.Display) is running (Automatic)."
    }
}

Write-Host "`nAll Hyper-V and Virtual Machine Platform features enabled."
Write-Host "A system restart is recommended for the changes to take effect." -ForegroundColor Yellow
