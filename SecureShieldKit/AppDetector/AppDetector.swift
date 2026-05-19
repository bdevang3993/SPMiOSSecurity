//
//  AppDetector.swift
//  SecureShieldKit
//
//  Created by Apple on 12/05/26.
//

import UIKit

public enum RemoteApps: String, CaseIterable {

    case anyDesk = "anydesk"
    case teamViewer = "teamviewer"
    case zoom = "zoomus"
    case skype = "skype"
    case chrome = "googlechrome"
    case whatsapp = "whatsapp"
    case telegram = "tg"
    case slack = "slack"
    case discord = "discord"
    case dropbox = "dbapi-2"
    case googleMeet = "googlemeet"
    case microsoftTeams = "msteams"
}

public class AppDetector {

    public static func isInstalled(_ app: RemoteApps) -> Bool {
        isInstalled(scheme: app.rawValue)
    }

    public static func isInstalled(scheme: String) -> Bool {
        let normalizedScheme = normalizeScheme(scheme)
        guard !normalizedScheme.isEmpty,
              let url = URL(string: "\(normalizedScheme)://") else {
            return false
        }

        return UIApplication.shared.canOpenURL(url)
    }

    public static func installedApps() -> [RemoteApps] {
        RemoteApps.allCases.filter {
            isInstalled($0)
        }
    }

    public static func installedSchemes(from schemes: [String]) -> [String] {
        schemes.filter {
            isInstalled(scheme: $0)
        }
    }

    private static func normalizeScheme(_ scheme: String) -> String {
        scheme
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "://", with: "")
    }
}
