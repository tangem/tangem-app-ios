import Foundation

public extension ContiguousBytes {
    /// A Data instance created safely from the contiguous bytes without making any copies.
    var dataRepresentation: Data {
        return withUnsafeBytes { bytes in
            let cfdata = CFDataCreateWithBytesNoCopy(nil, bytes.baseAddress?.assumingMemoryBound(to: UInt8.self), bytes.count, kCFAllocatorNull)
            return ((cfdata as NSData?) as Data?) ?? Data()
        }
    }

    /// 'dataRepresentation' isn't working reliably in MobileWallet creation flow, needs further investigation.
    var data: Data {
        withUnsafeBytes { buffer in
            Data(buffer)
        }
    }
}
