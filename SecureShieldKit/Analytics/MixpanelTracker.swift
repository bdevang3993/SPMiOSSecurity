import Foundation

internal enum MixpanelTracker {
    private static let endpoint = URL(string: "https://api.mixpanel.com/track")!

    internal static func track(
        event: String,
        token: String?,
        distinctId: String = UIDeviceIdentifier.current,
        properties: [String: Any] = [:]
    ) {
        guard let token, !token.isEmpty else { return }

        var eventProperties: [String: Any] = [
            "token": token,
            "distinct_id": distinctId,
            "time": Int(Date().timeIntervalSince1970)
        ]

        for (key, value) in properties {
            eventProperties[key] = value
        }

        let payload: [String: Any] = [
            "event": event,
            "properties": eventProperties
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formBody([
            "data": jsonString,
            "ip": "0"
        ])

        URLSession.shared.dataTask(with: request).resume()
    }

    private static func formBody(_ fields: [String: String]) -> Data? {
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._* ")
        let body = fields
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowedCharacters)?
                    .replacingOccurrences(of: " ", with: "+") ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowedCharacters)?
                    .replacingOccurrences(of: " ", with: "+") ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")

        return body.data(using: .utf8)
    }
}

private enum UIDeviceIdentifier {
    static var current: String {
        if let identifier = UserDefaults.standard.string(forKey: "SecureShieldKit.mixpanelDistinctId") {
            return identifier
        }

        let identifier = UUID().uuidString
        UserDefaults.standard.set(identifier, forKey: "SecureShieldKit.mixpanelDistinctId")
        return identifier
    }
}
