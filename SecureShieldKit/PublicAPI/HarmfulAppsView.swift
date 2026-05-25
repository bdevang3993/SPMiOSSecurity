//
//  HarmfulAppsView.swift
//  SecureShieldKit
//
//  Created by Antigravity on 25/05/26.
//

import SwiftUI

public struct HarmfulAppsView: View {
    public let harmfulAppSchemes: [String]
    public let installedHarmfulAppSchemes: [String]
    
    public init(
        harmfulAppSchemes: [String] = RemoteApps.allCases.map(\.rawValue),
        installedHarmfulAppSchemes: [String]? = nil
    ) {
        self.harmfulAppSchemes = harmfulAppSchemes
        if let installed = installedHarmfulAppSchemes {
            self.installedHarmfulAppSchemes = installed
        } else {
            self.installedHarmfulAppSchemes = AppDetector.installedSchemes(from: harmfulAppSchemes)
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Harmful Apps")
                .font(.headline)
            
            if harmfulAppSchemes.isEmpty {
                Text("No app schemes found in Info.plist.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(installedHarmfulAppSchemes.count) installed out of \(harmfulAppSchemes.count) checked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(harmfulAppSchemes, id: \.self) { scheme in
                            HStack {
                                Text(displayName(for: scheme))
                                Spacer()
                                Text(installedHarmfulAppSchemes.contains(scheme) ? "Installed" : "Not installed")
                                    .font(.caption)
                                    .foregroundStyle(installedHarmfulAppSchemes.contains(scheme) ? .red : .secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    public func displayName(for scheme: String) -> String {
        switch scheme {
        case "anydesk": return "AnyDesk"
        case "teamviewer": return "TeamViewer"
        case "zoomus": return "Zoom"
        case "skype": return "Skype"
        case "googlechrome": return "Google Chrome"
        case "whatsapp": return "WhatsApp"
        case "tg": return "Telegram"
        case "slack": return "Slack"
        case "discord": return "Discord"
        case "dbapi-2": return "Dropbox"
        case "googlemeet": return "Google Meet"
        case "msteams": return "Microsoft Teams"
        default: return scheme
        }
    }
}
