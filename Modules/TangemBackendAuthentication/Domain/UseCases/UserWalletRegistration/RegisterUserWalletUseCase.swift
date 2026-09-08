//
//  RegisterUserWalletUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId

public struct RegisterUserWalletUseCase: Sendable {
    private let prepare: PrepareUserWalletRegistrationUseCase
    private let submit: SubmitUserWalletRegistrationUseCase

    init(prepare: PrepareUserWalletRegistrationUseCase, submit: SubmitUserWalletRegistrationUseCase) {
        self.prepare = prepare
        self.submit = submit
    }

    public func callAsFunction(id: UserWalletId, signer: some UserWalletRegistrationSigner) async throws(RegisterUserWalletError) {
        guard let registrationRequest = try await prepareRegistrationRequest(id: id, signer: signer) else {
            // [REDACTED_TODO_COMMENT]
            return
        }

        try await submit(registrationRequest)
    }

    private func prepareRegistrationRequest(
        id: UserWalletId,
        signer: some UserWalletRegistrationSigner
    ) async throws(RegisterUserWalletError) -> UserWalletRegistrationRequest? {
        do {
            return try await prepare(id: id, signer: signer)
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
