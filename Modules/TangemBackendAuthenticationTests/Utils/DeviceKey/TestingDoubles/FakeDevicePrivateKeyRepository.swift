//
//  FakeDevicePrivateKeyRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
@testable import TangemBackendAuthentication

struct FakeDevicePrivateKeyRepository: DevicePrivateKeyRepository {
    func retrieve() throws(DevicePrivateKeyRepositoryError) -> FakeDevicePrivateKey {
        FakeDevicePrivateKey()
    }

    func delete() throws(DevicePrivateKeyRepositoryError) {}
}

struct FakeDevicePrivateKey: DevicePrivateKey {
    static let key = P256.Signing.PrivateKey()

    var publicKey: DevicePublicKey {
        get throws(DevicePublicKey.RawPointFormatError) {
            try DevicePublicKey(
                derRepresentation: Self.key.publicKey.derRepresentation,
                rawPoint: Self.key.publicKey.x963Representation
            )
        }
    }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature {
        try Self.key.signature(for: data)
    }
}
