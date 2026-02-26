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

  function detectInterfaces() {
    state = HotspotService.State.Busy
    detectProcess.running = true
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

  Process {
    id: checkProcess
    running: false
    command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n")
        let found = false
        for (let i = 0; i < lines.length; i++) {
          const parts = lines[i].trim().split(":")
          if (parts.length >= 2 && parts[1] === "802-11-wireless") {
            if (parts[0].toLowerCase().includes("hotspot") || parts[0].toLowerCase().includes("ap")) {
              found = true
              currentSsid = parts[0]
              break
            }
          }
        }
        
        if (found) {
          state = HotspotService.State.Active
          refreshDevices()
        } else {
          state = HotspotService.State.Idle
          currentSsid = ""
          connectedDevices = []
        }
      }
    }
  }

  function startHotspot(ssid, password) {
    if (!ssid || ssid.trim() === "") {
      lastError = "SSID required"
      return
    }
    if (!password || password.length < 8) {
      lastError = "Password must be 8+ chars"
      return
    }
    if (!wifiInterface) {
      lastError = "No WiFi interface"
      return
    }

    state = HotspotService.State.Busy
    lastError = ""
    
    startProcess.ssid = ssid.trim()
    startProcess.password = password
    startProcess.running = true
  }

  Process {
    id: startProcess
    property string ssid: ""
    property string password: ""
    running: false
    command: {
      const cmd = ["nmcli", "device", "wifi", "hotspot", 
                   "ifname", wifiInterface, 
                   "ssid", ssid, 
                   "con-name", ssid]
      if (password) cmd.push("password", password)
      return cmd
    }
    stdout: StdioCollector {}
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) console.log("start stderr:", text.trim())
      }
    }
    onExited: function() {
      if (this.exitCode === 0) {
        currentSsid = ssid
        Qt.callLater(() => {
          checkActiveHotspot()
        })
      } else {
        lastError = "Failed to start hotspot"
        state = HotspotService.State.Error
      }
    }
  }

  function stopHotspot() {
    if (state !== HotspotService.State.Active) return
    
    state = HotspotService.State.Busy
    stopProcess.running = true
  }

  Process {
    id: stopProcess
    running: false
    command: ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n")
        let conn = ""
        
        for (let i = 0; i < lines.length; i++) {
          const parts = lines[i].trim().split(":")
          if (parts.length >= 1) {
            const name = parts[0]
            if (name.toLowerCase().includes("hotspot") || name.toLowerCase().includes("ap") || name.includes("Hotspot")) {
              conn = name
              break
            }
          }
        }
        
        if (conn) {
          downProcess.conn = conn
          downProcess.running = true
        } else {
          state = HotspotService.State.Idle
        }
      }
    }
  }

  Process {
    id: downProcess
    property string conn: ""
    running: false
    command: ["nmcli", "connection", "down", conn]
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function() {
      connectedDevices = []
      currentSsid = ""
      state = HotspotService.State.Idle
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
    command: ["nmcli", "-t", "-f", "SSID,BSSID,STATE", "device", "wifi", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n")
        const devs = []
        
        for (let i = 0; i < lines.length; i++) {
          const parts = lines[i].trim().split(":")
          if (parts.length >= 3 && parts[2] === "connected") {
            if (parts[0]) {
              devs.push({ ssid: parts[0], mac: parts[1] || parts[0] })
            }
          }
        }
        
        connectedDevices = devs
      }
    }
  }

  function disconnectDevice(mac) {
    if (!mac || state !== HotspotService.State.Active) return
    discProcess.mac = mac
    discProcess.running = true
  }

  Process {
    id: discProcess
    property string mac: ""
    running: false
    command: ["nmcli", "device", "wifi", "disconnect", "bssid", mac]
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function() {
      Qt.callLater(refreshDevices)
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
