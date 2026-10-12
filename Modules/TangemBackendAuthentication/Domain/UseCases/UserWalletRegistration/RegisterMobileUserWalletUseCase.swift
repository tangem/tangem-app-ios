//
//  RegisterMobileUserWalletUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId
import struct TangemLogger.Logger

public struct RegisterMobileUserWalletUseCase: Sendable {
    private let obtainNonce: ObtainUserWalletRegistrationNonce
    private let attestUserWallet: AttestUserWallet
    private let submitRegistration: SubmitUserWalletRegistration

    private let analyticsReporter: any BackendAuthenticationAnalyticsReporter
    private let logger: Logger

    init(
        obtainNonce: @escaping ObtainUserWalletRegistrationNonce,
        attestUserWallet: @escaping AttestUserWallet,
        submitRegistration: @escaping SubmitUserWalletRegistration,
        analyticsReporter: some BackendAuthenticationAnalyticsReporter,
        logger: Logger
    ) {
        self.obtainNonce = obtainNonce
        self.attestUserWallet = attestUserWallet
        self.submitRegistration = submitRegistration
        self.analyticsReporter = analyticsReporter
        self.logger = logger
    }

    public func callAsFunction(
        id: UserWalletId,
        recoveryEnrollment: UserWalletRecoveryEnrollment?,
        signer: some UserWalletRegistrationSigner
    ) async throws(RegisterUserWalletError) {
        guard let nonce = try await obtainNonce(for: id) else {
            logger.debug("Skipping user wallet registration: already registered locally")
            return
        }

        guard let registrationRequest = try await attestUserWallet(withID: id, nonce: nonce, recoveryEnrollment: recoveryEnrollment, signer: signer) else {
            logger.debug("Skipping user wallet registration submission: already registered on the backend")
            return
        }

        try await submitRegistration(request: registrationRequest)
    }

    private func obtainNonce(for id: UserWalletId) async throws(RegisterUserWalletError) -> UserWalletRegistrationNonce? {
        do {
            return try await obtainNonce(id)
        } catch {
            switch error {
            case .clientFailure(.requestNonceTimeout):
                analyticsReporter.reportMobileUserWalletNonceTimeout()

            case .deviceRegistrationFailure,
                 .deviceKeyFailure,
                 .clientFailure,
                 .nonceDecryptionFailure,
                 .invalidDecryptedNonceEncoding:
                break
            }

            throw RegisterUserWalletError.obtainNonceFailure(error)
        }
    }

    private func attestUserWallet(
        withID id: UserWalletId,
        nonce: UserWalletRegistrationNonce,
        recoveryEnrollment: UserWalletRecoveryEnrollment?,
        signer: some UserWalletRegistrationSigner
    ) async throws(RegisterUserWalletError) -> UserWalletRegistrationRequest? {
        do {
            return try await attestUserWallet(id, nonce, recoveryEnrollment, signer)
        } catch {
            throw RegisterUserWalletError.attestUserWalletFailure(error)
        }
    }

    private func submitRegistration(request: UserWalletRegistrationRequest) async throws(RegisterUserWalletError) {
        do {
            try await submitRegistration(request)
        } catch {
            throw RegisterUserWalletError.submitFailure(error)
        }
    }
}
