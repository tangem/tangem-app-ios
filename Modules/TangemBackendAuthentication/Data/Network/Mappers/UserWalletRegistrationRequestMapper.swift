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
            walletSignature: domainRequest.attestation.walletSignature.value.base64EncodedString(),
            walletSignatureSalt: domainRequest.attestation.walletSignature.salt.base64EncodedString(),
            cardSignature: domainRequest.attestation.cardSignature?.value.base64EncodedString(),
            cardSignatureSalt: domainRequest.attestation.cardSignature?.salt.base64EncodedString(),
            walletStatus: domainRequest.attestation.origin.flatMap(mapStatus),
            attestationToken: domainRequest.appAttestationToken?.base64EncodedString(),
            metadata: DeviceMetadataMapper.mapToDTO(domainRequest.metadata)
        )
    }

    private static func mapStatus(fromDomain origin: UserWalletAttestation.Origin) -> String? {
        switch origin {
        case .generatedOnCard:
            Data([0x82]).base64EncodedString()

        case .seedImported:
            Data([0xC2]).base64EncodedString()
        }
    }
}
