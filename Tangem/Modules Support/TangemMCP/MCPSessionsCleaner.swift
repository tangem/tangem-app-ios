//
//  MCPSessionsCleaner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemMCP

final class MCPSessionsCleaner {
    @Injected(\.userWalletRepository) private var userWalletRepository: any UserWalletRepository

    private var bag: Set<AnyCancellable> = []

    func initialize() {
        guard FeatureProvider.isAvailable(.mcp) else { return }

        userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .sink { cleaner, event in
                cleaner.handleUserWalletRepositoryEvent(event)
            }
            .store(in: &bag)
    }
}

// MARK: - Private methods

private extension MCPSessionsCleaner {
    func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        guard case .deleted(let userWalletIDs, _) = event else { return }

        userWalletIDs.forEach(revokeSessions(for:))
    }

    func revokeSessions(for userWalletID: UserWalletId) {
        Task { [revokeUserWalletSessions = MCPAssembly.UseCases.revokeUserWalletSessions] in
            do throws(MCPSessionClientError) {
                try await revokeUserWalletSessions(for: userWalletID)
                MCPLogger.info("Revoked MCP sessions of a deleted user wallet")
            } catch {
                MCPLogger.warning("Failed to revoke MCP sessions of a deleted user wallet, error code \(error.errorCode)")
            }
        }
    }
}
