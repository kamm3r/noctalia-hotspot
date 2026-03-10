pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  enum State {
    Idle,
    Busy,
    Active,
    Error
  }

  property int state: HotspotService.State.Idle
  property bool isActive: state === HotspotService.State.Active
  property bool isLoading: state === HotspotService.State.Busy
  property string currentSsid: ""
  property var connectedDevices: []
  property string lastError: ""
  property string wifiInterface: "wlp15s0"
  property string internetInterface: "enp14s0"
  property string pendingSsid: ""
  property int pendingCheckAttempts: 0
  property int maxPendingCheckAttempts: 6

  function detectInterfaces() {
    state = HotspotService.State.Busy
    detectProcess.running = true
  }

  function clearPendingStart() {
    pendingSsid = ""
    pendingCheckAttempts = 0
    pendingCheckTimer.stop()
  }

  Process {
    id: detectProcess
    running: false
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n")
        let wifi = ""
        let eth = ""
        
        for (let i = 0; i < lines.length; i++) {
          const parts = lines[i].trim().split(":")
          if (parts.length >= 3) {
            const dev = parts[0]
            const type = parts[1]
            const st = parts[2]
            if (type === "wifi" && !wifi) wifi = dev
            if (type === "ethernet" && st === "connected" && !eth) eth = dev
          }
        }
        
        if (wifi) wifiInterface = wifi
        if (eth) internetInterface = eth
        
        state = HotspotService.State.Idle
        checkActiveHotspot()
      }
    }
  }

  function checkActiveHotspot() {
    checkProcess.running = true
  }

  function ensureSharingSupport() {
    sharingSupportProcess.running = true
  }

  Process {
    id: checkProcess
    running: false
    command: [
      "sh",
      "-c",
      "connection_name=$(nmcli -g GENERAL.CONNECTION device show \"$1\" 2>/dev/null | tr -d '\\r'); if [ -z \"$connection_name\" ] || [ \"$connection_name\" = \"--\" ]; then exit 0; fi; connection_mode=$(nmcli -g 802-11-wireless.mode connection show \"$connection_name\" 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '\\r'); if [ \"$connection_mode\" = \"ap\" ]; then printf '%s\\n' \"$connection_name\"; fi",
      "sh",
      wifiInterface
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        const detectedSsid = text.trim()

        if (detectedSsid !== "") {
          clearPendingStart()
          currentSsid = detectedSsid
          lastError = ""
          state = HotspotService.State.Active
          ensureSharingSupport()
          refreshDevices()
          return
        }

        connectedDevices = []
        currentSsid = ""

        if (pendingSsid !== "" && pendingCheckAttempts < maxPendingCheckAttempts) {
          pendingCheckAttempts += 1
          state = HotspotService.State.Busy
          pendingCheckTimer.restart()
          return
        }

        if (pendingSsid !== "") {
          lastError = startProcess.errorText || "Failed to start hotspot"
          clearPendingStart()
        }

        state = HotspotService.State.Idle
      }
    }
  }

  function startHotspot(ssid, password) {
    const trimmedSsid = ssid ? ssid.trim() : ""
    const normalizedPassword = password || ""

    if (!trimmedSsid) {
      lastError = "SSID required"
      return
    }
    if (normalizedPassword && normalizedPassword.length < 8) {
      lastError = "Password must be 8+ chars"
      return
    }
    if (normalizedPassword.length > 63) {
      lastError = "Password must be 63 chars or less"
      return
    }
    if (!wifiInterface) {
      lastError = "No WiFi interface"
      return
    }

    state = HotspotService.State.Busy
    lastError = ""

    pendingSsid = trimmedSsid
    pendingCheckAttempts = 0
    pendingCheckTimer.stop()

    startProcess.errorText = ""
    startProcess.ssid = trimmedSsid
    startProcess.password = normalizedPassword
    startProcess.running = true
  }

  Process {
    id: startProcess
    property string ssid: ""
    property string password: ""
    property string errorText: ""
    running: false
    command: [
      "sh",
      "-c",
      "ifname=\"$1\"; ssid=\"$2\"; password=\"$3\"; if ! nmcli -t -f NAME connection show | grep -Fx -- \"$ssid\" >/dev/null 2>&1; then nmcli connection add type wifi ifname \"$ifname\" con-name \"$ssid\" ssid \"$ssid\"; fi; if iw list 2>/dev/null | grep -Fq '5180.0 MHz [36]'; then band_args='802-11-wireless.band a 802-11-wireless.channel 36'; else band_args='802-11-wireless.band bg 802-11-wireless.channel 0'; fi; set -- $band_args; nmcli connection modify \"$ssid\" connection.interface-name \"$ifname\" 802-11-wireless.ssid \"$ssid\" 802-11-wireless.mode ap \"$@\" ipv4.method shared ipv4.addresses \"\" ipv4.gateway \"\" ipv4.dns \"\" ipv6.method ignore connection.autoconnect no; if [ -n \"$password\" ]; then nmcli connection modify \"$ssid\" 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.auth-alg open 802-11-wireless-security.proto rsn 802-11-wireless-security.pairwise ccmp 802-11-wireless-security.group ccmp 802-11-wireless-security.psk \"$password\"; else nmcli connection modify \"$ssid\" remove 802-11-wireless-security >/dev/null 2>&1 || true; fi; nmcli connection up \"$ssid\" ifname \"$ifname\"",
      "hotspot",
      wifiInterface,
      ssid,
      password
    ]
    stdout: StdioCollector {}
    stderr: StdioCollector {
      onStreamFinished: {
        startProcess.errorText = text.trim()
        if (text.trim()) console.log("start stderr:", text.trim())
      }
    }
    onExited: function() {
      pendingCheckTimer.restart()
    }
  }

  function stopHotspot() {
    if (state !== HotspotService.State.Active && currentSsid === "") return

    clearPendingStart()
    state = HotspotService.State.Busy
    lastError = ""
    stopProcess.conn = currentSsid
    stopProcess.running = true
  }

  Process {
    id: stopProcess
    property string conn: ""
    running: false
    command: [
      "sh",
      "-c",
      "connection_name=\"$2\"; if [ -z \"$connection_name\" ]; then connection_name=$(nmcli -g GENERAL.CONNECTION device show \"$1\" 2>/dev/null | tr -d '\\r'); fi; if [ -z \"$connection_name\" ] || [ \"$connection_name\" = \"--\" ]; then exit 1; fi; nmcli connection down \"$connection_name\"",
      "sh",
      wifiInterface,
      conn
    ]
    stdout: StdioCollector {}
    stderr: StdioCollector {
      onStreamFinished: {
        const errorText = text.trim()
        if (errorText) {
          lastError = errorText
        }
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0 && !lastError) {
        lastError = "Failed to stop hotspot"
      }
      checkActiveHotspot()
    }
  }

  function refreshDevices() {
    if (state !== HotspotService.State.Active) {
      connectedDevices = []
      return
    }
    refreshProcess.running = true
  }

  Process {
    id: refreshProcess
    running: false
    command: ["ip", "neigh", "show", "dev", wifiInterface]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n")
        const devs = []
        
        for (let i = 0; i < lines.length; i++) {
          const line = lines[i].trim()
          if (!line) continue
          
          // Parse: "10.42.0.225 lladdr f2:f0:6a:21:fe:97 REACHABLE"
          const parts = line.split(/\s+/)
          if (parts.length >= 3 && parts[1] === "lladdr") {
            const mac = parts[2].toUpperCase()
            const ip = parts[0]
            const linkState = parts[parts.length - 1]
            // Filter out incomplete entries
            if (mac !== "00:00:00:00:00:00" && mac !== "FF:FF:FF:FF:FF:FF" && linkState !== "FAILED") {
              devs.push({ mac: mac, ip: ip })
            }
          }
        }
        
        connectedDevices = devs
      }
    }
  }

  function disconnectDevice(mac) {
    if (!mac || state !== HotspotService.State.Active) return false

    lastError = "Disconnecting individual devices is not supported by NetworkManager here"
    return false
  }

  Process {
    id: sharingSupportProcess
    running: false
    command: [
      "sh",
      "-c",
      "hotspot_if=\"$1\"; upstream_if=\"$2\"; if ! command -v firewall-cmd >/dev/null 2>&1; then exit 0; fi; hotspot_zone=$(firewall-cmd --get-zone-of-interface=\"$hotspot_if\" 2>/dev/null); if [ -n \"$hotspot_zone\" ]; then firewall-cmd --zone=\"$hotspot_zone\" --add-forward >/dev/null 2>&1 || true; fi; if [ -n \"$upstream_if\" ]; then upstream_zone=$(firewall-cmd --get-zone-of-interface=\"$upstream_if\" 2>/dev/null); else upstream_zone=''; fi; if [ -z \"$upstream_zone\" ]; then upstream_zone=$(firewall-cmd --get-default-zone 2>/dev/null); fi; if [ -n \"$upstream_zone\" ]; then firewall-cmd --zone=\"$upstream_zone\" --add-masquerade >/dev/null 2>&1 || true; fi; if [ -n \"$hotspot_if\" ] && [ -n \"$upstream_if\" ]; then direct_rules=$(firewall-cmd --direct --get-all-rules 2>/dev/null || true); case \"$direct_rules\" in *\"ipv4 filter FORWARD 0 -i $hotspot_if -o $upstream_if -j ACCEPT\"*) ;; *) firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i \"$hotspot_if\" -o \"$upstream_if\" -j ACCEPT >/dev/null 2>&1 || true ;; esac; case \"$direct_rules\" in *\"ipv4 filter FORWARD 0 -i $upstream_if -o $hotspot_if -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT\"*) ;; *) firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i \"$upstream_if\" -o \"$hotspot_if\" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT >/dev/null 2>&1 || true ;; esac; case \"$direct_rules\" in *\"ipv4 nat POSTROUTING 0 -o $upstream_if -j MASQUERADE\"*) ;; *) firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -o \"$upstream_if\" -j MASQUERADE >/dev/null 2>&1 || true ;; esac; fi",
      "hotspot",
      wifiInterface,
      internetInterface
    ]
    stdout: StdioCollector {}
    stderr: StdioCollector {
      onStreamFinished: {
        const errorText = text.trim()
        if (errorText) {
          console.log("sharing support stderr:", errorText)
        }
      }
    }
  }

  Timer {
    id: pendingCheckTimer
    interval: 1000
    repeat: false
    onTriggered: {
      checkActiveHotspot()
    }
  }

  Timer {
    id: autoRefresh
    interval: 10000
    repeat: true
    onTriggered: {
      if (state === HotspotService.State.Active) {
        refreshDevices()
        checkActiveHotspot()
      }
    }
  }

  Component.onCompleted: {
    detectInterfaces()
    autoRefresh.start()
  }
}
