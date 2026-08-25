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

    var privateKey: StubDevicePrivateKey {
        get throws(DevicePrivateKeyRepositoryError) {
            switch result {
            case .success(let key):
                return key

            case .failure(let error):
                throw error
            }
        }
    }

    func removePrivateKey() {}
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
