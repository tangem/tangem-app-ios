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
        FakeDevicePrivateKey(key: P256.Signing.PrivateKey())
    }

    func delete() throws(DevicePrivateKeyRepositoryError) {}
}

struct FakeDevicePrivateKey: DevicePrivateKey {
    let key: P256.Signing.PrivateKey

    var publicKey: DevicePublicKey {
        get throws(DevicePublicKey.RawPointFormatError) {
            try DevicePublicKey(derRepresentation: key.publicKey.derRepresentation, rawPoint: key.publicKey.x963Representation)
        }
    }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature {
        try key.signature(for: data)
    }
}
