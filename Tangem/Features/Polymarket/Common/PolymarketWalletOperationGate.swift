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

    private let holders = OSAllocatedUnfairLock<[UserWalletId: Holder]>(initialState: [:])

    func exclusively<T>(
        _ userWalletId: UserWalletId,
        as holder: Holder,
        orThrow busyError: (_ currentHolder: Holder) -> Error,
        _ operation: () async throws -> T
    ) async throws -> T {
        let currentHolder = holders.withLock { holders -> Holder? in
            guard let currentHolder = holders[userWalletId] else {
                holders[userWalletId] = holder
                return nil
            }

            return currentHolder
        }

        if let currentHolder {
            throw busyError(currentHolder)
        }

        defer { holders.withLock { _ = $0.removeValue(forKey: userWalletId) } }

        return try await operation()
    }

    func isBusy(_ userWalletId: UserWalletId) -> Bool {
        holders.withLock { $0[userWalletId] != nil }
    }
}

extension PolymarketWalletOperationGate {
    enum Holder {
        case fastTradingChange
        case transaction
    }
}

struct PolymarketWalletOperationSlot {
    let userWalletId: UserWalletId
    let holder: PolymarketWalletOperationGate.Holder
    let gate: PolymarketWalletOperationGate
    let interruptedAuthorizations: PolymarketInterruptedAuthorizationStore
    let serverClock: PolymarketServerClock

    init(
        userWalletId: UserWalletId,
        holder: PolymarketWalletOperationGate.Holder = .transaction,
        gate: PolymarketWalletOperationGate = .shared,
        interruptedAuthorizations: PolymarketInterruptedAuthorizationStore = CommonPolymarketInterruptedAuthorizationStore(),
        serverClock: PolymarketServerClock = InjectedValues[\.polymarketServerClock]
    ) {
        self.userWalletId = userWalletId
        self.holder = holder
        self.gate = gate
        self.interruptedAuthorizations = interruptedAuthorizations
        self.serverClock = serverClock
    }

    func exclusively<T>(
        orThrow busyError: Error,
        whileFastTradingChangePends pendingError: Error,
        _ operation: () async throws -> T
    ) async throws -> T {
        try rejectWhileTheNextNonceIsHeld(orThrow: pendingError)

        return try await gate.exclusively(userWalletId, as: holder, orThrow: { $0 == .fastTradingChange ? pendingError : busyError }) {
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
            return try interruptedAuthorizations.load(for: userWalletId)?.isExecutable(at: serverClock.now) ?? false
        } catch {
            PolymarketLogger.error("Failed to read an interrupted fast trading authorization", error: error)
            return false
        }
    }
}
