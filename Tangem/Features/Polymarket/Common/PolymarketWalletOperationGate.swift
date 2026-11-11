//
//  PolymarketWalletOperationGate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

final class PolymarketWalletOperationGate: Sendable {
    static let shared = PolymarketWalletOperationGate()

    private let busyWallets = OSAllocatedUnfairLock<Set<UserWalletId>>(initialState: [])

    func exclusively<T>(
        _ userWalletId: UserWalletId,
        orThrow busyError: @autoclosure () -> Error,
        _ operation: () async throws -> T
    ) async throws -> T {
        let isAcquired = busyWallets.withLock { $0.insert(userWalletId).inserted }

        guard isAcquired else {
            throw busyError()
        }

        defer { busyWallets.withLock { _ = $0.remove(userWalletId) } }

        return try await operation()
    }

    func isBusy(_ userWalletId: UserWalletId) -> Bool {
        busyWallets.withLock { $0.contains(userWalletId) }
    }
}

struct PolymarketWalletOperationSlot {
    let userWalletId: UserWalletId
    let gate: PolymarketWalletOperationGate
    let interruptedAuthorizations: PolymarketInterruptedAuthorizationStore
    let serverClock: PolymarketServerClock

    init(
        userWalletId: UserWalletId,
        gate: PolymarketWalletOperationGate = .shared,
        interruptedAuthorizations: PolymarketInterruptedAuthorizationStore = CommonPolymarketInterruptedAuthorizationStore(),
        serverClock: PolymarketServerClock = InjectedValues[\.polymarketServerClock]
    ) {
        self.userWalletId = userWalletId
        self.gate = gate
        self.interruptedAuthorizations = interruptedAuthorizations
        self.serverClock = serverClock
    }

    func exclusively<T>(
        orThrow busyError: Error,
        whileKeptAuthorizationPends pendingError: Error,
        _ operation: () async throws -> T
    ) async throws -> T {
        try rejectWhileTheNextNonceIsHeld(orThrow: pendingError)

        return try await gate.exclusively(userWalletId, orThrow: busyError) {
            try rejectWhileTheNextNonceIsHeld(orThrow: pendingError)

            return try await operation()
        }
    }
}

// MARK: - Private implementation

private extension PolymarketWalletOperationSlot {
    func rejectWhileTheNextNonceIsHeld(orThrow pendingError: Error) throws {
        guard holdsTheNextNonce() else {
            return
        }

        PolymarketLogger.warning("A signed fast trading authorization still holds the next wallet nonce, the operation is not started")
        throw pendingError
    }

    func holdsTheNextNonce() -> Bool {
        do {
            return try interruptedAuthorizations.load(for: userWalletId)?.holdsWalletNonce(at: serverClock.now) ?? false
        } catch {
            PolymarketLogger.error("Failed to read an interrupted fast trading authorization", error: error)
            return false
        }
    }
}
