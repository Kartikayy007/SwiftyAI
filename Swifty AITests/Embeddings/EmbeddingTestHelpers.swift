import Foundation
import XCTest

extension URLRequest {
    func jsonBody() throws -> [String: Any] {
        let data = try XCTUnwrap(httpBody)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
