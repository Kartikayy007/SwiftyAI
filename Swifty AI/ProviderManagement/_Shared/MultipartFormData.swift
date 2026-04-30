import Foundation

struct MultipartFormData {
    let boundary: String
    private(set) var body = Data()

    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    mutating func appendField(name: String, value: String) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }

    mutating func appendFile(name: String, filename: String, mediaType: AIMediaType, data: Data) {
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mediaType.rawValue)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
    }

    mutating func finalize() -> Data {
        body.appendString("--\(boundary)--\r\n")
        return body
    }

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
