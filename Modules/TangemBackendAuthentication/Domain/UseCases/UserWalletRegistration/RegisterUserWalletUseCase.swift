//
//  RegisterUserWalletUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId

public struct RegisterUserWalletUseCase: Sendable {
    private let obtainNonce: ObtainUserWalletRegistrationNonceUseCase
    private let prepare: PrepareUserWalletRegistrationUseCase
    private let submit: SubmitUserWalletRegistrationUseCase

    init(
        obtainNonce: ObtainUserWalletRegistrationNonceUseCase,
        prepare: PrepareUserWalletRegistrationUseCase,
        submit: SubmitUserWalletRegistrationUseCase
    ) {
        self.obtainNonce = obtainNonce
        self.prepare = prepare
        self.submit = submit
    }

    public func callAsFunction(id: UserWalletId, signer: some UserWalletRegistrationSigner) async throws(RegisterUserWalletError) {
        guard let nonce = try await obtainNonce(for: id) else {
            // [REDACTED_TODO_COMMENT]
            return
        }

        guard let registrationRequest = try await prepareRegistrationRequest(id: id, nonce: nonce, signer: signer) else {
            // [REDACTED_TODO_COMMENT]
            return
        }

        try await submit(registrationRequest)
    }

    private func obtainNonce(for id: UserWalletId) async throws(RegisterUserWalletError) -> UserWalletRegistrationNonce? {
        do {
            return try await obtainNonce(id: id)
        } catch {
            throw RegisterUserWalletError.obtainNonceFailed(error)
        }
    }

    private func prepareRegistrationRequest(
        id: UserWalletId,
        nonce: UserWalletRegistrationNonce,
        signer: some UserWalletRegistrationSigner
    ) async throws(RegisterUserWalletError) -> UserWalletRegistrationRequest? {
        do {
            return try await prepare(id: id, nonce: nonce, signer: signer)
        } catch {
            throw RegisterUserWalletError.prepareFailed(error)
        }
    }

    private func submit(_ registrationRequest: UserWalletRegistrationRequest) async throws(RegisterUserWalletError) {
        do {
            try await submit(request: registrationRequest)
        } catch {
            throw RegisterUserWalletError.submitFailed(error)
        }
    }
}
