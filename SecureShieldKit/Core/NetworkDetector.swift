import Foundation
import NetworkExtension

public final class NetworkDetector: NetworkDetecting {
    public let threatType: ThreatType = .unsecureWifi
    
    public init() {}
    
    public func scan() async -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        if await isWifiUnsecure() {
            threats.append(SecurityThreat(
                type: .unsecureWifi,
                level: .medium,
                metadata: ["description": "Connected to an unsecured Wi-Fi network (no password)."]
            ))
        }
        
        if await isHotspotActive() {
            threats.append(SecurityThreat(
                type: .unsecureHotspot,
                level: .low,
                metadata: ["description": "Connected to a potential personal hotspot."]
            ))
        }
        
        if isVPNActive() {
            threats.append(SecurityThreat(
                type: .vpnActive,
                level: .low,
                metadata: ["description": "VPN connection is active (V2)."]
            ))
        }
        
        return threats
    }
    
    public func isWifiUnsecure() async -> Bool {
        return await withCheckedContinuation { continuation in
            if #available(iOS 14.0, *) {
                NEHotspotNetwork.fetchCurrent { network in
                    guard let network = network else {
                        continuation.resume(returning: false)
                        return
                    }
                    // isSecure is true if the network is password protected
                    continuation.resume(returning: !network.isSecure)
                }
            } else {
                // Fallback for older iOS versions if needed, though most modern apps target 14+
                continuation.resume(returning: false)
            }
        }
    }
    
    public func isHotspotActive() async -> Bool {
        return await withCheckedContinuation { continuation in
            if #available(iOS 14.0, *) {
                NEHotspotNetwork.fetchCurrent { network in
                    guard let network = network else {
                        continuation.resume(returning: false)
                        return
                    }
                    
                    // Heuristic: Many hotspots have "Hotspot" in their SSID
                    // or are Open networks with common hotspot patterns.
                    let ssid = network.ssid.lowercased()
                    if ssid.contains("hotspot") || ssid.contains("iphone") || ssid.contains("ipad") {
                        // This is a weak heuristic but one of the few available without private APIs
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            } else {
                continuation.resume(returning: false)
            }
        }
    }

//    public func isVPNActive() -> Bool {
//        // NUCLEAR OPTION: Completely skip VPN checks on Simulator.
//        #if targetEnvironment(simulator)
//        return false
//        #endif
//        
//        if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
//            return false
//        }
//
//        // 1. Check System Proxy Settings (Reliable for active user VPNs)
//        if let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [AnyHashable: Any] {
//            // Check for explicit VPN key which is often present for active VPNs
//            if settings["VPN"] != nil { return true }
//
//            if let scoped = settings["__SCOPED__"] as? [String: Any] {
//                // We include common VPN protocols: tap, tun, ppp, ipsec, utun.
//                // Note: 'utun' is very common for modern VPNs (WireGuard, OpenVPN).
//                // 'ppp' and 'ipsec' are used by older VPN protocols but also by some system services.
//                let vpnProtocols = ["tap", "tun", "ppp", "ipsec", "utun"] 
//                for key in scoped.keys {
//                    for protocolName in vpnProtocols {
//                        if key.lowercased().contains(protocolName) {
//                            print("[SecureShieldKit] VPN detected via scoped proxy settings: \(key)")
//                            return true 
//                        }
//                    }
//                }
//            }
//        }
//
//        // 2. Secondary check via network interfaces with Point-to-Point verification
//        var ifaddr: UnsafeMutablePointer<ifaddrs>?
//        guard getifaddrs(&ifaddr) == 0 else { return false }
//        defer { freeifaddrs(ifaddr) }
//
//        var ptr = ifaddr
//        while ptr != nil {
//            defer { ptr = ptr?.pointee.ifa_next }
//            guard let interface = ptr?.pointee else { continue }
//            
//            let name = String(cString: interface.ifa_name)
//            let flags = Int32(interface.ifa_flags)
//            
//            // VPN interfaces (tun/tap) are Point-to-Point
//            let isPointToPoint = (flags & IFF_POINTOPOINT) != 0
//            guard isPointToPoint else { continue }
//            
//            // Common VPN prefixes: tun, tap, utun, ppp, ipsec.
//            // We include 'utun' as it's the standard for modern VPNs on iOS.
//            // We include 'ipsec' and 'ppp' to ensure coverage for all VPN types.
//            let vpnPrefixes = ["tun", "tap", "utun", "ppp", "ipsec"]
//            if vpnPrefixes.contains(where: { name.hasPrefix($0) }) {
//                print("[SecureShieldKit] VPN detected via network interface: \(name)")
//                return true
//            }
//        }
//        return false
//    }
    
    public func isVPNActive() -> Bool {

          guard let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any],
                let scopes = settings["__SCOPED__"] as? [String: Any] else {
              return false
          }

          let vpnProtocols = [
              "tap",
              "tun",
              "ppp",
              "ipsec",
              "utun"
          ]

          for key in scopes.keys {
              for protocolName in vpnProtocols {
                  if key.contains(protocolName) {
                      return true
                  }
              }
          }

          return false
      }
    
}
