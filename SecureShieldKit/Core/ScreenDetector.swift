import UIKit

public final class ScreenDetector: ScreenDetecting {
    public let threatType: ThreatType = .screenCaptured
    
    public init() {}
    
    public func scan() async -> [SecurityThreat] {
        var threats: [SecurityThreat] = []
        
        if isScreenCaptured() {
            threats.append(SecurityThreat(
                type: .screenCaptured,
                level: .medium,
                metadata: ["description": "Screen is currently being recorded, mirrored, or shared."]
            ))
        }
        
        return threats
    }
    
    public func isScreenCaptured() -> Bool {
        return UIScreen.main.isCaptured
    }
}
