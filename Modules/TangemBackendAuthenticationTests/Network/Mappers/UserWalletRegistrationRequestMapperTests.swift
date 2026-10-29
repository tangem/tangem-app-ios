//
//  UserWalletRegistrationRequestMapperTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import struct TangemFoundation.UserWalletId
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct UserWalletRegistrationRequestMapperTests {
    @Test(arguments: Self.appAssertions)
    func mapFromDomainProducesCorrectRegisterWalletDTORequest(appAssertion: AppAssertion?) {
        let walletAttestation = UserWalletAttestation(
            walletSignature: UserWalletAttestation.Signature(value: Data([0x0A]), salt: Data([0x0B])),
            cardSignature: UserWalletAttestation.Signature(value: Data([0x0C]), salt: Data([0x0D])),
            walletStatus: Data([0x02])
        )
        let recoveryEnrollment = UserWalletRecoveryEnrollment(
            providerIdToken: "some provider id token",
            encryptedRecoveryKey: "some encrypted recovery key"
        )
        let request = UserWalletRegistrationRequest(
            id: UserWalletId.fake,
            walletAttestation: walletAttestation,
            decryptedNonce: "some decrypted nonce",
            appAssertion: appAssertion,
            metadata: DeviceMetadata.fake,
            recoveryEnrollment: recoveryEnrollment
        )

        let dto = UserWalletRegistrationRequestMapper.map(fromDomain: request)

        #expect(dto.nonce == request.decryptedNonce)
        #expect(dto.walletId == request.id.value.base64EncodedString())
        #expect(dto.walletSignature == walletAttestation.walletSignature.value.base64EncodedString())
        #expect(dto.walletSignatureSalt == walletAttestation.walletSignature.salt.base64EncodedString())
        #expect(dto.cardSignature == walletAttestation.cardSignature?.value.base64EncodedString())
        #expect(dto.cardSignatureSalt == walletAttestation.cardSignature?.salt.base64EncodedString())
        #expect(dto.walletStatus == walletAttestation.walletStatus?.base64EncodedString())
        #expect(dto.attestationToken == appAssertion?.object.base64EncodedString())
        #expect(dto.appAttestKeyId == appAssertion?.keyID)
        #expect(dto.providerIdToken == recoveryEnrollment.providerIdToken)
        #expect(dto.encryptedRecoveryKey == recoveryEnrollment.encryptedRecoveryKey)
        #expect(dto.metadata.deviceModel == request.metadata.deviceModel)
    }
}

extension UserWalletRegistrationRequestMapperTests {
    static let appAssertions: [AppAssertion?] = [
        AppAssertion.fake,
        nil,
    ]
}
