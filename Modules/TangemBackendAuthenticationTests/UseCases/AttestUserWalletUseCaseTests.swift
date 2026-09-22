//
//  AttestUserWalletUseCaseTests.swift
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
struct AttestUserWalletUseCaseTests {
    @Test
    func attestUserWalletReturnsSignedRequestOnSuccess() async throws {
        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()

        let signer = SpyUserWalletRegistrationSigner()
        let expectedWalletAttestation = UserWalletAttestation(
            walletSignature: UserWalletAttestation.Signature(
                value: Data("some wallet signature".utf8),
                salt: Data("some wallet salt".utf8)
            ),
            cardSignature: UserWalletAttestation.Signature(
                value: Data("some card signature".utf8),
                salt: Data("some card salt".utf8)
            ),
            origin: .generatedOnCard
        )
        signer.attestResult = Result.success(expectedWalletAttestation)

        let expectedID = UserWalletId.fake
        let expectedNonceBytesToSign = Data([0x01, 0x02, 0x03])
        let expectedDecryptedNonce = "some decrypted nonce"
        let expectedAppAttestationToken = Data("some attestation token".utf8)
        let nonce = UserWalletRegistrationNonce(
            value: expectedDecryptedNonce,
            bytesToSign: expectedNonceBytesToSign,
            appAttestationToken: expectedAppAttestationToken
        )

        let sut = makeSUT(registrationStatusRepository: registrationStatusRepository)

        let request = try #require(await sut(id: expectedID, nonce: nonce, signer: signer))

        let expectedRequest = UserWalletRegistrationRequest(
            id: expectedID,
            walletAttestation: expectedWalletAttestation,
            decryptedNonce: expectedDecryptedNonce,
            appAttestationToken: expectedAppAttestationToken,
            metadata: DeviceMetadata.fake
        )
        #expect(request == expectedRequest)

        #expect(registrationStatusRepository.receivedMessages == [.retrieve(expectedID)])
        #expect(signer.receivedMessages == [.attest(expectedNonceBytesToSign)])
    }

    @Test
    func attestUserWalletReturnsNilWhenAlreadyRegisteredLocally() async throws {
        let registrationStatusRepository = SpyUserWalletRegistrationStatusRepository()
        registrationStatusRepository.retrieveResult = true

        let signer = SpyUserWalletRegistrationSigner()

        let sut = makeSUT(registrationStatusRepository: registrationStatusRepository)

        let request = try await sut(id: UserWalletId.fake, nonce: .fake, signer: signer)

        #expect(request == nil)
        #expect(signer.receivedMessages.isEmpty)
        #expect(registrationStatusRepository.receivedMessages == [.retrieve(UserWalletId.fake)])
    }

    @Test
    func attestUserWalletThrowsSignerFailureWhenSigningFails() async throws {
        let signer = SpyUserWalletRegistrationSigner()
        let expectedUnderlyingError = AnyTestError()
        signer.attestResult = Result.failure(.signingFailed(underlying: expectedUnderlyingError))

        let sut = makeSUT()

        let error = try await #require(throws: AttestUserWalletError.self) {
            _ = try await sut(id: UserWalletId.fake, nonce: .fake, signer: signer)
        }

        guard case .signerFailure(.signingFailed(underlying: expectedUnderlyingError)) = error else {
            Issue.record("Expected .signerFailure(.signingFailed), got \(error)")
            return
        }
    }
}

// MARK: - Factory methods

extension AttestUserWalletUseCaseTests {
    private func makeSUT(
        registrationStatusRepository: some UserWalletRegistrationStatusRepository = SpyUserWalletRegistrationStatusRepository()
    ) -> AttestUserWalletUseCase {
        AttestUserWalletUseCase(
            registrationStatusRepository: registrationStatusRepository,
            deviceMetadataProvider: .fake
        )
    }
}
