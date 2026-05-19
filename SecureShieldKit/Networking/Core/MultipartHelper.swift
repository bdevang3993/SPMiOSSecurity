import Foundation

/// A helper struct designed to easily generate multipart/form-data request payloads.
public struct MultipartForm {
    
    /// The unique boundary used to separate fields in the body content.
    public let boundary: String
    
    private var bodyData = Data()
    
    /// Initialize with a custom or auto-generated boundary.
    public init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }
    
    /// Append a text field to the form data payload.
    public mutating func append(value: String, name: String) {
        bodyData.append("--\(boundary)\r\n")
        bodyData.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        bodyData.append("\(value)\r\n")
    }
    
    /// Append binary file/image data to the form data payload.
    public mutating func append(fileData: Data, name: String, filename: String, mimeType: String) {
        bodyData.append("--\(boundary)\r\n")
        bodyData.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        bodyData.append("Content-Type: \(mimeType)\r\n\r\n")
        bodyData.append(fileData)
        bodyData.append("\r\n")
    }
    
    /// Seal and finalize the multipart body structure.
    public mutating func finalize() -> Data {
        var finalData = bodyData
        finalData.append("--\(boundary)--\r\n")
        return finalData
    }
}

fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
