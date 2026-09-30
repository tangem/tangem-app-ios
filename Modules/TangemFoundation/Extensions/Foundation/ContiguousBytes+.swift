import Foundation

public extension ContiguousBytes {
    /// A `Data` instance created from the contiguous bytes.
    ///
    /// This copies the bytes. The previous implementation used
    /// `CFDataCreateWithBytesNoCopy(..., kCFAllocatorNull)`, which hands out a `Data`
    /// backed by a pointer that is only valid inside `withUnsafeBytes`; using it after
    /// the closure returns is undefined behaviour (the observed "garbage with zeros" in
    /// the MobileWallet creation flow). Copy so the returned `Data` owns its storage.
    var dataRepresentation: Data {
        return data
    }

    var data: Data {
        withUnsafeBytes { buffer in
            Data(buffer)
        }
    }
}
