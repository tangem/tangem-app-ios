//
//  PolymarketOnboardingFastTrading.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketOnboardingFastTrading: AnyObject {
    var isEnabled: Bool { get set }

    func makeAuthorization(depositWalletAddress: String, nonce: String) -> PolymarketRelayedBatch.Unsigned?

    @discardableResult
    func submit(_ authorization: PolymarketRelayedBatch) -> Task<Void, Never>?
}

final class CommonPolymarketOnboardingFastTrading {
    typealias Authorize = (_ batch: PolymarketRelayedBatch, _ grant: PolymarketSessionKeyGrant) async throws -> Void

    private let userWalletId: UserWalletId
    private let keyStore: PolymarketSessionKeyStore
    private let serverClock: PolymarketServerClock
    private let authorize: Authorize
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(
        userWalletId: UserWalletId,
        keyStore: PolymarketSessionKeyStore,
        serverClock: PolymarketServerClock,
        authorize: @escaping Authorize
    ) {
        self.userWalletId = userWalletId
        self.keyStore = keyStore
        self.serverClock = serverClock
        self.authorize = authorize
    }
}

// MARK: - PolymarketOnboardingFastTrading protocol conformance

extension CommonPolymarketOnboardingFastTrading: PolymarketOnboardingFastTrading {
    var isEnabled: Bool {
        get { state.withLock { $0.isEnabled } }
        set { state.withLock { $0.isEnabled = newValue } }
    }

    func makeAuthorization(depositWalletAddress: String, nonce: String) -> PolymarketRelayedBatch.Unsigned? {
        do {
            let sessionKeyAddress = try keyStore.heldAddress(for: userWalletId) ?? keyStore.generateKey(for: userWalletId)

            let authorization = try PolymarketSessionKeyAuthorizationBatch(
                sessionKeyAddress: sessionKeyAddress,
                depositWalletAddress: depositWalletAddress,
                nonce: nonce,
                now: serverClock.now,
                deadlineOffset: PolymarketSessionKeyAuthorizationBatch.followUpDeadlineOffset
            )

            state.withLock { $0.pendingGrant = authorization.grant }

            return authorization.unsigned
        } catch {
            PolymarketLogger.error("Failed to prepare the fast trading authorization for onboarding", error: error)
            return nil
        }
    }

    @discardableResult
    func submit(_ authorization: PolymarketRelayedBatch) -> Task<Void, Never>? {
        let grant = state.withLock { state in
            defer { state.pendingGrant = nil }
            return state.pendingGrant
        }

        guard let grant else { return nil }

        let authorize = authorize

        return Task {
            do {
                try await authorize(authorization, grant)
            } catch {
                PolymarketLogger.error("The fast trading authorization signed during onboarding did not go through", error: error)
            }
        }
    }
}

// MARK: - Auxiliary types

private extension CommonPolymarketOnboardingFastTrading {
    struct State {
        var isEnabled = true
        var pendingGrant: PolymarketSessionKeyGrant?
    }
}
