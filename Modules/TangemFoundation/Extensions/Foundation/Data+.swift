import Foundation

public extension Data {
    var bytes: [UInt8] {
        return Array(self)
    }

    func leadingZeroPadding(toLength newLength: Int) -> Data {
        guard count < newLength else { return self }

        let prefix = Data(repeating: UInt8(0), count: newLength - count)
        return prefix + self
    }

    func trailingZeroPadding(toLength newLength: Int) -> Data {
        guard count < newLength else { return self }

        let suffix = Data(repeating: UInt8(0), count: newLength - count)
        return self + suffix
    }
}

// MARK: - Convenience extensions

extension Data {
    /// Uppercase hex string representation, no separators (e.g., "AABBCC...").
    ///
    /// Named `hexEncodedString` rather than `hexString` to avoid call-site ambiguity in modules
    /// that `@testable` import both `TangemFoundation` (which exposes internals) and `TangemSdk`,
    /// the latter already declaring a public `Data.hexString` of the same shape.
    var hexEncodedString: String {
        return map { String(format: "%02X", $0) }.joined()
    }
}
