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

    /// Zeroes the buffer in place; `memset_s` cannot be optimized away. Best effort by nature:
    /// it covers this instance only, not copies made by COW, coders or the crypto layer.
    mutating func secureErase() {
        withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            _ = memset_s(baseAddress, bytes.count, 0, bytes.count)
        }
    }
}
