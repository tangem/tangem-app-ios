//
//  ObtainRecoveryAppAssertionUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLogger
@testable import TangemBackendAuthentication

@Suite("Recovery app assertion", .tags(.backendAuthentication))
struct ObtainRecoveryAppAssertionUseCaseTests {
    @Test("An attested app asserts the nonce bytes and hands the assertion back")
    func attestedAppAsserts() async {
        let appAttestService = SpyAppAttestService()
        let expectedAppAssertion = AppAssertion(keyID: "some key id", object: Data("some assertion object".utf8))
        appAttestService.assertResult = Result.success(expectedAppAssertion)

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()
        appAttestationStatusRepository.retrieveResult = true

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository
        )

        let appAssertion = await sut(nonce: Self.nonce)

        #expect(appAssertion == expectedAppAssertion)
        #expect(appAttestService.receivedMessages == [.assert(Data(Self.nonce.utf8))])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve])
    }

    @Test("An app without an accepted key skips App Attest and returns no assertion")
    func notAttestedAppSkipsAssertion() async {
        let appAttestService = SpyAppAttestService()
        appAttestService.assertResult = Result.success(AppAssertion.fake)

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()
        appAttestationStatusRepository.retrieveResult = false

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository
        )

        let appAssertion = await sut(nonce: Self.nonce)

        #expect(appAssertion == nil)
        #expect(appAttestService.receivedMessages.isEmpty)
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve])
    }

    @Test(
        "A missing or malformed assertion key clears the attestation status, so the next authentication attests again",
        arguments: [
            AppAttestServiceError.assertionKeyCorrupted,
            AppAttestServiceError.assertionKeyNotFound,
        ]
    )
    func unavailableKeyClearsStatus(keyUnavailableError: AppAttestServiceError) async {
        let appAttestService = SpyAppAttestService()
        appAttestService.assertResult = Result.failure(keyUnavailableError)

        let appAttestationStatusRepository = SpyAppAttestationStatusRepository()
        appAttestationStatusRepository.retrieveResult = true

        let sut = makeSUT(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository
        )

        let appAssertion = await sut(nonce: Self.nonce)

        #expect(appAssertion == nil)
        #expect(appAttestService.receivedMessages == [.assert(Data(Self.nonce.utf8))])
        #expect(appAttestationStatusRepository.receivedMessages == [.retrieve, .persist(false)])
    }
}

// MARK: - Factory methods

extension ObtainRecoveryAppAssertionUseCaseTests {
    private func makeSUT(
        appAttestService: some AppAttestService,
        appAttestationStatusRepository: some AppAttestationStatusRepository
    ) -> ObtainRecoveryAppAssertionUseCase {
        ObtainRecoveryAppAssertionUseCase(
            appAttestService: appAttestService,
            appAttestationStatusRepository: appAttestationStatusRepository,
            logger: Logger(category: OSLogCategory(name: "Tests"))
        )
    }
}

// MARK: - Fixtures

extension ObtainRecoveryAppAssertionUseCaseTests {
    private static let nonce = "some-recovery-nonce"
}
