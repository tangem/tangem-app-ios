//
//  SecureEnclaveDevicePrivateKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import struct Foundation.Data

/// Wraps a real, hardware-backed `SecureEnclave.P256.Signing.PrivateKey`.
/// Only usable when `SecureEnclave.isAvailable`, i.e. real devices, never the simulator.
///
/// - Note: SecureEnclave.P256.Signing.PrivateKey can not be constructed without the real Secure Enclave.
/// This is the primary reason why DevicePrivateKey wrapper types exist.
struct SecureEnclaveDevicePrivateKey: DevicePrivateKey {
    private let key: SecureEnclave.P256.Signing.PrivateKey

    var publicKey: DevicePublicKey {
        get throws(DevicePublicKey.RawPointFormatError) {
            try DevicePublicKey(derRepresentation: key.publicKey.derRepresentation, rawPoint: key.publicKey.x963Representation)
        }
    }

    init(key: SecureEnclave.P256.Signing.PrivateKey) {
        self.key = key
    }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature {
        try key.signature(for: data)
    }
}
