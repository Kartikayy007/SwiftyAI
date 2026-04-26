import Foundation

func httpPost(url: URL, headers: [String: String], body: Encodable, session: URLSession = .shared) async throws -> Data {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
    }

    do {
        request.httpBody = try JSONEncoder().encode(body)
    } catch {
        throw AIError.encodingError(error)
    }

    let (data, response): (Data, URLResponse)
    do {
        (data, response) = try await session.data(for: request)
    } catch {
        throw AIError.networkError(error)
    }

    guard let http = response as? HTTPURLResponse else {
        throw AIError.invalidResponse
    }

    guard (200..<300).contains(http.statusCode) else {
        let message = apiErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
        throw AIError.apiError(statusCode: http.statusCode, message: message)
    }

    return data
}

private func apiErrorMessage(from data: Data) -> String? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return String(data: data, encoding: .utf8)
    }
    if let error = json["error"] as? [String: Any], let msg = error["message"] as? String {
        return msg
    }
    if let message = json["message"] as? String {
        return message
    }
    return String(data: data, encoding: .utf8)
}
