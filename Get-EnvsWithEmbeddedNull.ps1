##########################################
## Used to check for null values in given
## branch of registry to fix errors in
## starting PowerShell
##########################################

function Check($key) {
    foreach ($name in $key.GetValueNames()) {
        if ($key.GetValue($name).ToString().Contains("`0")) {
            Write-Output "$($key.Name): $($name)"
        }
    }
}

$hklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, 0)
$hkcu = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::CurrentUser, 0)

Check($hklm.OpenSubKey('Software\Microsoft\Windows\CurrentVersion'))
Check($hklm.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment'))
Check($hkcu.OpenSubKey('Environment'))

$volenv = $hkcu.OpenSubKey('Volatile Environment')
Check($volenv)
foreach ($name in $volenv.GetSubKeyNames()) {
    Check($volenv.OpenSubKey($name))
}