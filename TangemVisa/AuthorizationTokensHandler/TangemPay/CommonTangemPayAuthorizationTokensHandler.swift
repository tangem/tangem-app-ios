//
//  CommonTangemPayAuthorizationTokensHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

public enum TangemPayAuthorizationTokensHandlerError: Error {
    case preparingFailed
}

final class CommonTangemPayAuthorizationTokensHandler {
    private let customerWalletId: String
    private let authorizationService: TangemPayAuthorizationService
    private let setSyncNeeded: () -> Void
    private let setUnavailable: () -> Void

    private weak var authorizationTokensSaver: TangemPayAuthorizationTokensSaver?

    private let authorizationTokensHolder = ThreadSafeContainer<TangemPayAuthorizationTokens?>(nil)
    private let taskCoordinator = TaskCoordinator()

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
        guard let tokens = authorizationTokensHolder.read() else {
            setSyncNeeded()
            return false
        }

        if tokens.refreshTokenExpired {
            setSyncNeeded()
            return false
        }

        if tokens.accessTokenExpired {
            do {
                let newTokens = try await authorizationService.refreshTokens(
                    refreshToken: tokens.refreshToken
                )
                try? saveTokens(tokens: newTokens)

                // Either:
                // 1. Maximum allowed refresh token reuse exceeded
                // 2. Session doesn't have required client
            } catch let error as TangemPayAPIErrorResponse where ["invalid_credentials", "invalid_token"].contains(error.code) {
                // Call of `forceRefreshToken` func could fail if same refresh becomes invalid (not expired, but invalid)
                // That could happen if:
                // 1. Token refresh called twice on the same device (could happen in there is a race condition somewhere)
                // 2. User have one TangemPay account linked to more than one device
                // (i.e. calling token refresh on one device automatically makes refresh token on second device invalid)
                setSyncNeeded()
                VisaLogger.error("Failed to refresh token", error: error)
                return false
            } catch {
                setUnavailable()
                VisaLogger.error("Failed to refresh token", error: error)
                return false
            }
        }

        return true
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
        let preparingSucceededTask = await taskCoordinator.getOrCreateTask { [weak self] in
            await self?.refreshTokenIfNeeded() ?? false
        }

        let preparingSucceeded = await preparingSucceededTask.value

        if !preparingSucceeded {
            throw TangemPayAuthorizationTokensHandlerError.preparingFailed
        }
    }
}

private actor TaskCoordinator {
    private var currentTask: Task<Bool, Never>?

    func getOrCreateTask(action: @escaping () async -> Bool) -> Task<Bool, Never> {
        if let existingTask = currentTask {
            return existingTask
        }

        let newTask = Task { [weak self] in
            let result = await action()
            await self?.clearTask()
            return result
        }
        currentTask = newTask
        return newTask
    }

    private func clearTask() {
        currentTask = nil
    }
}
