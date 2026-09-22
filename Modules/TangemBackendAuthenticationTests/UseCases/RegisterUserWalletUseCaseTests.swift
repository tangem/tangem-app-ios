//
//  RegisterUserWalletUseCaseTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import struct TangemFoundation.UserWalletId
import TangemLogger
@testable import TangemBackendAuthentication

@Suite(.tags(.backendAuthentication))
struct RegisterUserWalletUseCaseTests {
    @Test
    func registerUserWalletObtainsNonceAttestsAndSubmitsRegistrationOnSuccess() async throws {
        let expectedID = UserWalletId.fake
        let expectedNonce = UserWalletRegistrationNonce.fake
        let expectedRequest = UserWalletRegistrationRequest.fake
        let expectedSigner = SpyUserWalletRegistrationSigner()

        let sut = makeSUT(
            obtainNonce: Self.obtainNonceMock(expectedID: expectedID, returnedNonce: expectedNonce),
            attestUserWallet: Self.attestUserWalletMock(
                expectedID: expectedID,
                expectedNonce: expectedNonce,
                expectedSigner: expectedSigner,
                returnedRequest: expectedRequest
            ),
            submitRegistration: Self.submitRegistrationMock(expectedRequest: expectedRequest)
        )

        try await sut(id: expectedID, signer: expectedSigner)
    }

    @Test
    func registerUserWalletReturnsEarlyWhenNonceUnavailable() async throws {
        let anyUserWalletID = UserWalletId.fake

        let sut = makeSUT(
            obtainNonce: Self.obtainNonceMock(expectedID: anyUserWalletID, returnedNonce: nil),
            attestUserWallet: Self.neverCalledAttestUserWalletMock(),
            submitRegistration: Self.neverCalledSubmitRegistrationMock()
        )

        try await sut(id: anyUserWalletID, signer: .successStub)
    }

    @Test
    func registerUserWalletReturnsEarlyWhenAttestationSkipped() async throws {
        let anyUserWalletID = UserWalletId.fake
        let anyNonce = UserWalletRegistrationNonce.fake
        let anySigner = SpyUserWalletRegistrationSigner()

        let sut = makeSUT(
            obtainNonce: Self.obtainNonceMock(expectedID: anyUserWalletID, returnedNonce: anyNonce),
            attestUserWallet: Self.attestUserWalletMock(
                expectedID: anyUserWalletID,
                expectedNonce: anyNonce,
                expectedSigner: anySigner,
                returnedRequest: nil
            ),
            submitRegistration: Self.neverCalledSubmitRegistrationMock()
        )

        try await sut(id: anyUserWalletID, signer: anySigner)
    }

    @Test
    func registerUserWalletThrowsObtainNonceFailureWhenObtainNonceFails() async throws {
        let expectedUnderlyingError = AnyTestError()

        let sut = makeSUT(
            obtainNonce: { _ throws(ObtainUserWalletRegistrationNonceError) in
                throw ObtainUserWalletRegistrationNonceError.clientFailure(.requestNonceFailed(underlying: expectedUnderlyingError))
            },
            attestUserWallet: Self.neverCalledAttestUserWalletMock(),
            submitRegistration: Self.neverCalledSubmitRegistrationMock()
        )

        let error = try await #require(throws: RegisterUserWalletError.self) {
            try await sut(id: UserWalletId.fake, signer: SpyUserWalletRegistrationSigner())
        }

        guard case .obtainNonceFailure(.clientFailure(.requestNonceFailed(underlying: expectedUnderlyingError))) = error else {
            Issue.record("Expected .obtainNonceFailure(.clientFailure(.requestNonceFailed)), got \(error)")
            return
        }
    }

    @Test
    func registerUserWalletThrowsAttestUserWalletFailureWhenAttestationFails() async throws {
        let anyUserWalletID = UserWalletId.fake
        let expectedUnderlyingError = AnyTestError()

        let sut = makeSUT(
            obtainNonce: Self.obtainNonceMock(expectedID: anyUserWalletID),
            attestUserWallet: { _, _, _ throws(AttestUserWalletError) in
                throw AttestUserWalletError.signerFailure(.signingFailed(underlying: expectedUnderlyingError))
            },
            submitRegistration: Self.neverCalledSubmitRegistrationMock()
        )

        let error = try await #require(throws: RegisterUserWalletError.self) {
            try await sut(id: anyUserWalletID, signer: SpyUserWalletRegistrationSigner())
        }

        guard case .attestUserWalletFailure(.signerFailure(.signingFailed(underlying: expectedUnderlyingError))) = error else {
            Issue.record("Expected .attestUserWalletFailure(.signerFailure(.signingFailed)), got \(error)")
            return
        }
    }

    @Test
    func registerUserWalletThrowsSubmitFailureWhenSubmitRegistrationFails() async throws {
        let expectedID = UserWalletId.fake
        let expectedNonce = UserWalletRegistrationNonce.fake
        let expectedRequest = UserWalletRegistrationRequest.fake
        let expectedUnderlyingError = AnyTestError()
        let expectedSigner = SpyUserWalletRegistrationSigner()

        let sut = makeSUT(
            obtainNonce: Self.obtainNonceMock(expectedID: expectedID, returnedNonce: expectedNonce),
            attestUserWallet: Self.attestUserWalletMock(
                expectedID: expectedID,
                expectedNonce: expectedNonce,
                expectedSigner: expectedSigner,
                returnedRequest: expectedRequest
            ),
            submitRegistration: { actualRequest throws(SubmitUserWalletRegistrationError) in
                #expect(actualRequest == expectedRequest)
                throw SubmitUserWalletRegistrationError.clientFailure(.registerFailed(underlying: expectedUnderlyingError))
            }
        )

        let error = try await #require(throws: RegisterUserWalletError.self) {
            try await sut(id: expectedID, signer: expectedSigner)
        }

        guard case .submitFailure(.clientFailure(.registerFailed(underlying: expectedUnderlyingError))) = error else {
            Issue.record("Expected .submitFailure(.clientFailure(.registerFailed)), got \(error)")
            return
        }
    }
}

// MARK: - Factory methods

extension RegisterUserWalletUseCaseTests {
    private func makeSUT(
        obtainNonce: @escaping ObtainUserWalletRegistrationNonce,
        attestUserWallet: @escaping AttestUserWallet,
        submitRegistration: @escaping SubmitUserWalletRegistration
    ) -> RegisterUserWalletUseCase {
        RegisterUserWalletUseCase(
            obtainNonce: obtainNonce,
            attestUserWallet: attestUserWallet,
            submitRegistration: submitRegistration,
            logger: Logger(category: OSLogCategory(name: "Tests"))
        )
    }

    private static func obtainNonceMock(
        expectedID: UserWalletId,
        returnedNonce: UserWalletRegistrationNonce? = UserWalletRegistrationNonce.fake,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> ObtainUserWalletRegistrationNonce {
        { actualID in
            #expect(actualID == expectedID, sourceLocation: sourceLocation)

            return await confirmation(expectedCount: 1, sourceLocation: sourceLocation) { confirmation in
                confirmation.confirm()
                return returnedNonce
            }
        }
    }

    private static func attestUserWalletMock(
        expectedID: UserWalletId,
        expectedNonce: UserWalletRegistrationNonce,
        expectedSigner: SpyUserWalletRegistrationSigner,
        returnedRequest: UserWalletRegistrationRequest?,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> AttestUserWallet {
        { actualID, actualNonce, actualSigner in
            #expect(actualID == expectedID, sourceLocation: sourceLocation)
            #expect(actualNonce == expectedNonce, sourceLocation: sourceLocation)
            #expect((actualSigner as? SpyUserWalletRegistrationSigner) === expectedSigner, sourceLocation: sourceLocation)

            return await confirmation(expectedCount: 1, sourceLocation: sourceLocation) { confirmation in
                confirmation.confirm()
                return returnedRequest
            }
        }
    }

    private static func neverCalledAttestUserWalletMock(sourceLocation: SourceLocation = #_sourceLocation) -> AttestUserWallet {
        { _, _, _ in
            return await confirmation(expectedCount: 0, sourceLocation: sourceLocation) { confirmation in
                confirmation.confirm()
                return nil
            }
        }
    }

    private static func submitRegistrationMock(
        expectedRequest: UserWalletRegistrationRequest,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> SubmitUserWalletRegistration {
        { actualRequest in
            #expect(actualRequest == expectedRequest, sourceLocation: sourceLocation)

            await confirmation(expectedCount: 1, sourceLocation: sourceLocation) { confirmation in
                confirmation.confirm()
            }
        }
    }

    private static func neverCalledSubmitRegistrationMock(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> SubmitUserWalletRegistration {
        { _ in
            await confirmation(expectedCount: 0, sourceLocation: sourceLocation) { confirmation in
                confirmation.confirm()
            }
        }
    }
}
