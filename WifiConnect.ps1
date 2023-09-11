# Function to disconnect from the current Wi-Fi connection
Function Disconnect-WiFi {
    $currentConnection = Get-NetConnectionProfile
    if ($null -ne $currentConnection.InterfaceAlias ) {
        Write-Host "Disconnecting from $($currentConnection.Name)"
        netsh wlan disconnect
    }
}

# Function to connect to a specific Wi-Fi network by SSID
Function Connect-WiFi([string]$ssid) {
    $ssid = $ssid.Trim()
    Write-Host "Connecting to network: $ssid"
    netsh wlan connect name=$ssid ssid=$ssid 
}

# Function to get the signal strength of a specific SSID
Function Get-SignalStrength([string]$ssid) {
    $networks = netsh wlan show networks mode=Bssid | Select-String "SSID", "Signal"
    # Loop through the list and display SSID and Signal Strength
    for ($i = 0; $i -lt $networks.Count; $i ++) {
        if ($networks[$i].Line.Contains("$ssid")){
            $signalData = $networks[$i +2]
            [int]$signalStrength = $signalData.ToString().Replace('%', '').Split(':')[1].Trim()
            return $signalStrength
        }
    }
}
Function Get-SignalBand([string]$ssid) {
    $networks = netsh wlan show networks mode=Bssid | Select-String "SSID", "Band"
    # Loop through the list and display SSID and Signal Strength
    for ($i = 0; $i -lt $networks.Count; $i ++) {
        if ($networks[$i].Line.Contains("$ssid")){
            $signalData = $networks[$i +2]
            $signalBand = $signalData.ToString().Split(':')[1].Trim()
            return $signalBand
        }
    }
}

Function Get-BestSignal {
    $wifiProfiles = netsh wlan show profiles | Select-String "All User Profile"
    $bestProfileName = ""
    $bestSignalStrength
    for($i = 0; $i -lt $wifiProfiles.Count; $i++){
        $profileName = $wifiProfiles[$i] -replace '^\s+All User Profile\s+:\s+', ''
        $signal = Get-SignalStrength -ssid $profileName
        if ($signal -gt $bestSignalStrength){
            $bestSignalStrength = $signal
            $bestProfileName = $profileName.ToString().Trim()
        }
    }
    return $bestProfileName
}

Function Get-BestSignalWithBand($bandType) {
    $wifiProfiles = netsh wlan show profiles | Select-String "All User Profile"
    $bestProfileName = ""
    $bestSignalStrength
    for($i = 0; $i -lt $wifiProfiles.Count; $i++){
        $profileName = $wifiProfiles[$i] -replace '^\s+All User Profile\s+:\s+', ''
        $signal = Get-SignalStrength -ssid $profileName
        if((Get-SignalBand $profileName) -ne $bandType){continue}
        if ($signal -gt $bestSignalStrength){
            $bestSignalStrength = $signal
            $bestProfileName = $profileName.ToString().Trim()
        }
    }
    return $bestProfileName
}

Function Disconnect{
    $currentConnection = (Get-NetConnectionProfile)
    if($null -eq $currentConnection){
        return
    }
    $signalStrength = Get-SignalStrength -ssid $currentConnection.Name
    if ($signalStrength -gt 80 ){
        Write-host "Good Connection. No need to change."
        Exit 0
    }else{
        Disconnect-WiFi
    }
}


Function Main{
    Disconnect
    $network = Get-BestSignalWithBand "5 GHz"
    if((Get-SignalStrength $network) -lt 66 ){
        $network = Get-BestSignalWithBand "2.4 GHz"
    }
    Connect-WiFi -ssid $network
}

Main

