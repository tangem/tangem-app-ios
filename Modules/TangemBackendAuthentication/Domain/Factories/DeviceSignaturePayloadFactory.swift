//
//  DeviceSignaturePayloadFactory.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

enum DeviceSignaturePayloadFactory {
    static func make(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        attestationToken: Data?,
        metadata: DeviceMetadata
    ) -> Data {
        let joined = [
            devicePublicKey.derRepresentation.base64EncodedString(),
            decryptedNonce,
            attestationToken?.base64EncodedString() ?? "",
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
