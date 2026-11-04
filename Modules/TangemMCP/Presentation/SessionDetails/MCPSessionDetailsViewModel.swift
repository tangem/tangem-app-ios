//
//  MCPSessionDetailsViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import protocol Combine.ObservableObject
public import struct Combine.Published
private import Foundation
import struct TangemLogger.Logger
public import protocol TangemUI.FloatingSheetContentViewModel

@MainActor
public final class MCPSessionDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    private let sessionID: MCPSession.ID
    private let revokeSession: RevokeMCPSessionUseCase
    private let delegate: Delegate
    private let analyticsReporter: any MCPSessionsAnalyticsReporter
    private let logger: TangemLogger.Logger

    private var revokeSessionTask: Task<Void, Never>?

    @Published private(set) var state: MCPSessionDetailsState

    init(
        session: MCPSession,
        userWallet: MCPUserWallet,
        revokeSession: RevokeMCPSessionUseCase,
        delegate: Delegate,
        analyticsReporter: some MCPSessionsAnalyticsReporter,
        logger: TangemLogger.Logger
    ) {
        sessionID = session.id
        self.revokeSession = revokeSession
        self.delegate = delegate
        self.analyticsReporter = analyticsReporter
        self.logger = logger

        state = MCPSessionDetailsState(
            connectionDate: session.createdAt.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()),
            agent: session.agent,
            userWallet: MCPSessionDetailsState.UserWalletRow(name: userWallet.name, thumbnail: userWallet.thumbnail)
        )
    }

    func handle(action: MCPSessionDetailsAction) {
        switch action {
        case .closeButtonTapped:
            delegate.closeButtonTapped()

        case .revokeButtonTapped:
            handleRevokeButtonTapped()

        case .sessionRevoked(let result):
            handleSessionRevoked(result)
        }
    }

    private func handleRevokeButtonTapped() {
        guard revokeSessionTask == nil else { return }

        state.revokeButton.isLoading = true

        // [REDACTED_USERNAME], strong self capture is intentional. Revoke result must still reach the delegate
        // when the sheet is closed while the request is in flight. Task is cleaned in handle method. No memory leak here.
        revokeSessionTask = Task { [strongSelf = self] in
            strongSelf.logger.debug("Revoking MCP session")

            do throws(MCPSessionClientError) {
                try await strongSelf.revokeSession(sessionID: strongSelf.sessionID)
                strongSelf.handle(action: .sessionRevoked(Result.success(())))
            } catch {
                strongSelf.handle(action: .sessionRevoked(Result.failure(error)))
            }
        }
    }

    private func handleSessionRevoked(_ result: Result<Void, MCPSessionClientError>) {
        revokeSessionTask = nil
        state.revokeButton.isLoading = false

        switch result {
        case .success:
            logger.debug("MCP session revoked")
            analyticsReporter.reportAgentDisconnected(agent: state.agent)
            delegate.sessionRevoked()

        case .failure(let error):
            logger.error("Failed to revoke MCP session", error: error)
            delegate.sessionRevokeFailed(error)
        }
    }
}

// MARK: - Nested types

extension MCPSessionDetailsViewModel {
    struct Delegate {
        let closeButtonTapped: () -> Void
        let sessionRevoked: () -> Void
        let sessionRevokeFailed: (MCPSessionClientError) -> Void
    }
}
