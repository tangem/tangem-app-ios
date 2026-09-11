//
//  StubDevicePrivateKeyRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
@testable import TangemBackendAuthentication

struct StubDevicePrivateKeyRepository: DevicePrivateKeyRepository {
    let result: Result<StubDevicePrivateKey, DevicePrivateKeyRepositoryError>

    func retrieve() throws(DevicePrivateKeyRepositoryError) -> StubDevicePrivateKey {
        switch result {
        case .success(let key):
            return key

        case .failure(let error):
            throw error
        }
    }

    func delete() throws(DevicePrivateKeyRepositoryError) {}
}

struct StubDevicePrivateKey: DevicePrivateKey {
    let publicKeyResult: Result<DevicePublicKey, DevicePublicKey.RawPointFormatError>
    let signResult: Result<P256.Signing.ECDSASignature, any Error>

    var publicKey: DevicePublicKey {
        get throws(DevicePublicKey.RawPointFormatError) {
            switch publicKeyResult {
            case .success(let key):
                return key
            case .failure(let error):
                throw error
            }
        }
    }

    func signature(for data: Data) throws -> P256.Signing.ECDSASignature {
        try signResult.get()
    }
}
