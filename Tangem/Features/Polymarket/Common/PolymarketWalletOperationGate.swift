//
//  PolymarketWalletOperationGate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

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
}

struct PolymarketWalletOperationSlot: Sendable {
    let userWalletId: UserWalletId
    let gate: PolymarketWalletOperationGate

    init(userWalletId: UserWalletId, gate: PolymarketWalletOperationGate = .shared) {
        self.userWalletId = userWalletId
        self.gate = gate
    }
}
