import Darwin
import Foundation
import MachO

enum DyldImageScanner {
    static func loadedImageNames() -> [String] {
        let count = _dyld_image_count()
        return (0..<count).compactMap { index in
            guard let name = _dyld_get_image_name(index) else { return nil }
            return String(cString: name).lowercased()
        }
    }

    static func containsAny(_ needles: [String]) -> [String] {
        let normalizedNeedles = needles.map { $0.lowercased() }
        return loadedImageNames().filter { image in
            normalizedNeedles.contains { image.contains($0) }
        }
    }
}
