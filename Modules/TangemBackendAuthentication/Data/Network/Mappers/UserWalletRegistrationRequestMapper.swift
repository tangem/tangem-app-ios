//
//  UserWalletRegistrationRequestMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct TangemFoundation.UserWalletId

enum UserWalletRegistrationRequestMapper {
    static func map(fromDomain domainRequest: UserWalletRegistrationRequest) -> RegisterWalletDTO.Request {
        RegisterWalletDTO.Request(
            nonce: domainRequest.decryptedNonce,
            walletId: domainRequest.id.value.base64EncodedString(),
            walletSignature: domainRequest.walletAttestation.walletSignature.value.base64EncodedString(),
            walletSignatureSalt: domainRequest.walletAttestation.walletSignature.salt.base64EncodedString(),
            cardSignature: domainRequest.walletAttestation.cardSignature?.value.base64EncodedString(),
            cardSignatureSalt: domainRequest.walletAttestation.cardSignature?.salt.base64EncodedString(),
            walletStatus: domainRequest.walletAttestation.walletStatus?.base64EncodedString(),
            attestationToken: domainRequest.appAttestationToken?.base64EncodedString(),
            providerIdToken: domainRequest.recoveryEnrollment?.providerIdToken,
            encryptedRecoveryKey: domainRequest.recoveryEnrollment?.encryptedRecoveryKey,
            metadata: DeviceMetadataMapper.mapToDTO(domainRequest.metadata)
        )
    }
}
