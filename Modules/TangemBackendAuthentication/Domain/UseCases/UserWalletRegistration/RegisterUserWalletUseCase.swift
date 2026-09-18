//
//  RegisterUserWalletUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId

public struct RegisterUserWalletUseCase: Sendable {
    private let obtainNonce: ObtainUserWalletRegistrationNonce
    private let attestUserWallet: AttestUserWallet
    private let submitRegistration: SubmitUserWalletRegistration

    init(
        obtainNonce: @escaping ObtainUserWalletRegistrationNonce,
        attestUserWallet: @escaping AttestUserWallet,
        submitRegistration: @escaping SubmitUserWalletRegistration
    ) {
        self.obtainNonce = obtainNonce
        self.attestUserWallet = attestUserWallet
        self.submitRegistration = submitRegistration
    }

    public func callAsFunction(id: UserWalletId, signer: some UserWalletRegistrationSigner) async throws(RegisterUserWalletError) {
        guard let nonce = try await obtainNonce(for: id) else {
            // [REDACTED_TODO_COMMENT]
            return
        }

        guard let registrationRequest = try await attestUserWallet(withID: id, nonce: nonce, signer: signer) else {
            // [REDACTED_TODO_COMMENT]
            return
        }

        try await submitRegistration(request: registrationRequest)
    }

    private func obtainNonce(for id: UserWalletId) async throws(RegisterUserWalletError) -> UserWalletRegistrationNonce? {
        do {
            return try await obtainNonce(id)
        } catch {
            throw RegisterUserWalletError.obtainNonceFailure(error)
        }
    }

    private func attestUserWallet(
        withID id: UserWalletId,
        nonce: UserWalletRegistrationNonce,
        signer: some UserWalletRegistrationSigner
    ) async throws(RegisterUserWalletError) -> UserWalletRegistrationRequest? {
        do {
            return try await attestUserWallet(id, nonce, signer)
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
