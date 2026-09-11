//
//  DevicePrivateKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import enum CryptoKit.P256
import struct Foundation.Data

/// A device's private key, capable of exposing its public counterpart and signing data with it.
///
/// The only production implementation is `SecureEnclaveDevicePrivateKey`,
/// wrapping a real, hardware-backed `SecureEnclave.P256.Signing.PrivateKey`.
///
/// - SeeAlso: ``DevicePublicKey`` for more information.
protocol DevicePrivateKey: Sendable {
    var publicKey: DevicePublicKey {
        get throws(DevicePublicKey.RawPointFormatError)
    }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature
}
