//
//  DeviceSignaturePayloadFactory.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum DeviceSignaturePayloadFactory {
    static func make(
        nonce: String,
        recoveryEncryptionPublicKey: String,
        providerIdToken: String,
        attestationToken: String?,
        appAttestKeyId: String?,
        metadata: DeviceMetadataDTO
    ) -> Data {
        let joined = [
            nonce,
            recoveryEncryptionPublicKey,
            providerIdToken,
            attestationToken ?? .empty,
            appAttestKeyId ?? .empty,
            metadata.deviceModel,
            metadata.os,
            metadata.osVersion,
            metadata.appVersion,
            metadata.userAgent,
            metadata.locale,
            metadata.timezone,
        ].joined(separator: ":")

        return Data(joined.utf8)
    }
}
