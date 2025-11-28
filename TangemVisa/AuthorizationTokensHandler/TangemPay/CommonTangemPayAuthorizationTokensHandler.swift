//
//  CommonTangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

enum TangemPayAuthorizationTokensHandlerError: Error {
    case preparingFailed
}

final class CommonTangemPayAuthorizationTokensHandler {
    private let customerWalletId: String
    private let authorizationService: TangemPayAuthorizationService
    private let setSyncNeeded: () -> Void
    private let setUnavailable: () -> Void

    private weak var authorizationTokensSaver: TangemPayAuthorizationTokensSaver?

    private let authorizationTokensHolder = ThreadSafeContainer<TangemPayAuthorizationTokens?>(nil)
    private let tokenPreparingSucceededTask = ThreadSafeContainer<Task<Bool, Never>?>(nil)

    init(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService,
        setSyncNeeded: @escaping () -> Void,
        setUnavailable: @escaping () -> Void
    ) {
        self.customerWalletId = customerWalletId
        self.authorizationService = authorizationService
        self.setSyncNeeded = setSyncNeeded
        self.setUnavailable = setUnavailable
    }

    private func refreshTokenIfNeeded() async -> Bool {
        if authorizationTokensHolder.read()?.refreshTokenExpired ?? true {
            setSyncNeeded()
            return false
        }

        if authorizationTokensHolder.read()?.accessTokenExpired ?? true {
            do {
                try await refreshTokens()

                // Either:
                // 1. Maximum allowed refresh token reuse exceeded
                // 2. Session doesn't have required client
            } catch let error as TangemPayAPIErrorResponse where error.code == "invalid_credentials" {
                // Call of `forceRefreshToken` func could fail if same refresh becomes invalid (not expired, but invalid)
                // That could happen if:
                // 1. Token refresh called twice on the same device (could happen in there is a race condition somewhere)
                // 2. User have one TangemPay account linked to more than one device
                // (i.e. calling token refresh on one device automatically makes refresh token on second device invalid)
                setSyncNeeded()
                return false
            } catch {
                setUnavailable()
                return false
            }
        }

        return true
    }

    private func refreshTokens() async throws {
        guard let tokens = authorizationTokensHolder.read() else {
            return
        }

        if tokens.refreshTokenExpired {
            throw VisaAuthorizationTokensHandlerError.refreshTokenExpired
        }

        let newTokens = try await authorizationService.refreshTokens(refreshToken: tokens.refreshToken)

        if newTokens.accessTokenExpired {
            throw VisaAuthorizationTokensHandlerError.failedToUpdateAccessToken
        }

        try saveTokens(tokens: newTokens)
    }
}

extension CommonTangemPayAuthorizationTokensHandler: TangemPayAuthorizationTokensHandler {
    var authorizationHeader: String? {
        guard let tokens = authorizationTokensHolder.read() else {
            return nil
        }
        return AuthorizationTokensUtility.getAuthorizationHeader(from: tokens)
    }

    func setupAuthorizationTokensSaver(_ authorizationTokensSaver: any TangemPayAuthorizationTokensSaver) {
        self.authorizationTokensSaver = authorizationTokensSaver
    }

    func saveTokens(tokens: TangemPayAuthorizationTokens) throws {
        authorizationTokensHolder.mutate {
            $0 = tokens
        }

        try authorizationTokensSaver?.saveAuthorizationTokensToStorage(
            tokens: tokens,
            customerWalletId: customerWalletId
        )
    }

    func prepare() async throws {
        if let tokenPreparingSucceededTask = tokenPreparingSucceededTask.read() {
            let succeeded = await tokenPreparingSucceededTask.value
            if !succeeded {
                throw TangemPayAuthorizationTokensHandlerError.preparingFailed
            }
            return
        }

        let tokenPreparingSucceededTask = _Concurrency.Task { [self] in
            await refreshTokenIfNeeded()
        }
        self.tokenPreparingSucceededTask.mutate {
            $0 = tokenPreparingSucceededTask
        }

        let succeeded = await tokenPreparingSucceededTask.value
        self.tokenPreparingSucceededTask.mutate {
            $0 = nil
        }

        if !succeeded {
            throw TangemPayAuthorizationTokensHandlerError.preparingFailed
        }
    }
}
