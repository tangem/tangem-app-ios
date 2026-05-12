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
    /// Kept internal to `TangemFoundation` module to avoid call-site ambiguity with `TangemSdk`'s
    /// public `Data.hexString` in modules that import both.
    var hexString: String {
        return map { String(format: "%02X", $0) }.joined()
    }
}
