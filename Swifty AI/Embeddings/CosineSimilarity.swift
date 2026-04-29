import Foundation

public func cosineSimilarity(_ lhs: [Double], _ rhs: [Double]) -> Double {
    guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }

    var dotProduct = 0.0
    var lhsMagnitude = 0.0
    var rhsMagnitude = 0.0

    for index in lhs.indices {
        dotProduct += lhs[index] * rhs[index]
        lhsMagnitude += lhs[index] * lhs[index]
        rhsMagnitude += rhs[index] * rhs[index]
    }

    guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 0 }
    return dotProduct / (sqrt(lhsMagnitude) * sqrt(rhsMagnitude))
}
