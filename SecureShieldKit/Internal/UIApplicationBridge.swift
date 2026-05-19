#if canImport(UIKit)
import Foundation
import UIKit

enum UIApplicationBridge {
    static func canOpenURL(_ url: URL) -> Bool {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                UIApplication.shared.canOpenURL(url)
            }
        }

        var result = false
        DispatchQueue.main.sync {
            result = MainActor.assumeIsolated {
                UIApplication.shared.canOpenURL(url)
            }
        }
        return result
    }
}
#endif
