import Foundation

func httpPost(
    url: URL,
    headers: [String: String],
    body: Encodable,
    session: URLSession = .shared,
    options: GenerationOptions = GenerationOptions()
) async throws -> Data {
    let encodedBody: Data
    do {
        encodedBody = try JSONEncoder().encode(body)
    } catch {
        throw AIError.encodingError(error)
    }

    let maxAttempts = max(1, options.retryPolicy.maxAttempts)
    var lastError: Error?

    for attempt in 1...maxAttempts {
        if Task.isCancelled {
            throw CancellationError()
        }

        do {
            return try await sendHTTPPost(
                url: url,
                headers: headers,
                body: encodedBody,
                session: session,
                options: options
            )
        } catch let error as AIError {
            if shouldRetry(error, policy: options.retryPolicy), attempt < maxAttempts {
                lastError = error
            } else {
                throw error
            }
        } catch {
            throw error
        }

        try await Task.sleep(for: options.retryPolicy.baseDelay)
    }

    throw lastError ?? AIError.invalidResponse
}

func httpPostData(
    url: URL,
    headers: [String: String],
    body: Data,
    contentType: String,
    session: URLSession = .shared,
    options: GenerationOptions = GenerationOptions()
) async throws -> Data {
    let maxAttempts = max(1, options.retryPolicy.maxAttempts)
    var lastError: Error?

    for attempt in 1...maxAttempts {
        if Task.isCancelled {
            throw CancellationError()
        }

        do {
            return try await sendHTTPPost(
                url: url,
                headers: headers,
                body: body,
                contentType: contentType,
                session: session,
                options: options
            )
        } catch let error as AIError {
            if shouldRetry(error, policy: options.retryPolicy), attempt < maxAttempts {
                lastError = error
            } else {
                throw error
            }
        } catch {
            throw error
        }

        try await Task.sleep(for: options.retryPolicy.baseDelay)
    }

    throw lastError ?? AIError.invalidResponse
}

func httpGetData(
    url: URL,
    headers: [String: String],
    session: URLSession = .shared,
    options: GenerationOptions = GenerationOptions()
) async throws -> Data {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
    }
    for (key, value) in options.headers {
        request.setValue(value, forHTTPHeaderField: key)
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

private func sendHTTPPost(
    url: URL,
    headers: [String: String],
    body: Data,
    session: URLSession,
    options: GenerationOptions
) async throws -> Data {
    try await sendHTTPPost(
        url: url,
        headers: headers,
        body: body,
        contentType: "application/json",
        session: session,
        options: options
    )
}

private func sendHTTPPost(
    url: URL,
    headers: [String: String],
    body: Data,
    contentType: String,
    session: URLSession,
    options: GenerationOptions
) async throws -> Data {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
    for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
    }
    for (key, value) in options.headers {
        request.setValue(value, forHTTPHeaderField: key)
    }
    request.httpBody = body

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

private func shouldRetry(_ error: AIError, policy: RetryPolicy) -> Bool {
    switch error {
    case .apiError(let statusCode, _):
        return policy.retryableStatusCodes.contains(statusCode)
    case .networkError:
        return true
    default:
        return false
    }
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
