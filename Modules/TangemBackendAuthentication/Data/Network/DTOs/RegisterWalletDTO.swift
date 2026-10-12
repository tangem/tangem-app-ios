//
//  RegisterWalletDTO.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// `POST api/authentication/v1/mobile/wallet/register`
enum RegisterWalletDTO {
    struct Request: Encodable {
        let nonce: String
        let walletId: String
        let walletSignature: String
        let walletSignatureSalt: String
        let cardSignature: String?
        let cardSignatureSalt: String?
        let walletStatus: String?
        let attestationToken: String?
        let providerIdToken: String?
        let encryptedRecoveryKey: String?
        let metadata: DeviceMetadataDTO.Request
    }
}
