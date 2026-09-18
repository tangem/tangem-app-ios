//
//  StubDevicePrivateKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
@testable import TangemBackendAuthentication

struct StubDevicePrivateKey: DevicePrivateKey {
    var publicKeyResult: Result<DevicePublicKey, DevicePublicKey.RawPointFormatError>
    var signResult: Result<P256.Signing.ECDSASignature, any Error>

    init() {
        let publicKeyResult: Result<DevicePublicKey, DevicePublicKey.RawPointFormatError> = Result(
            catching: { () throws(DevicePublicKey.RawPointFormatError) -> DevicePublicKey in
                let key = P256.Signing.PrivateKey()
                return try DevicePublicKey(
                    derRepresentation: key.publicKey.derRepresentation,
                    rawPoint: key.publicKey.x963Representation
                )
            }
        )

        let signResult: Result<P256.Signing.ECDSASignature, any Error> = Result { try P256.Signing.ECDSASignature.fake }

        self.init(publicKeyResult: publicKeyResult, signResult: signResult)
    }

    private init(
        publicKeyResult: Result<DevicePublicKey, DevicePublicKey.RawPointFormatError>,
        signResult: Result<P256.Signing.ECDSASignature, any Error>
    ) {
        self.publicKeyResult = publicKeyResult
        self.signResult = signResult
    }

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
