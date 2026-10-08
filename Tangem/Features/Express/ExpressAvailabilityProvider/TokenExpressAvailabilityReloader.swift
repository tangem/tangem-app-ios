//
//  TokenExpressAvailabilityReloader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TokenExpressAvailabilityReloader {
    private let expressAvailabilityProvider: ExpressAvailabilityProvider
    private let tokenItem: TokenItem
    private let userWalletId: UserWalletId
    private let shouldLoadExpressAvailability: Bool

    init(
        expressAvailabilityProvider: ExpressAvailabilityProvider,
        tokenItem: TokenItem,
        userWalletId: UserWalletId,
        shouldLoadExpressAvailability: Bool
    ) {
        self.expressAvailabilityProvider = expressAvailabilityProvider
        self.tokenItem = tokenItem
        self.userWalletId = userWalletId
        self.shouldLoadExpressAvailability = shouldLoadExpressAvailability
    }

    func reloadIfNeeded() async {
        guard
            shouldLoadExpressAvailability,
            expressAvailabilityProvider.swapState(for: tokenItem) == .notLoaded,
            expressAvailabilityProvider.onrampState(for: tokenItem) == .notLoaded
        else {
            return
        }

        expressAvailabilityProvider.updateExpressAvailability(
            for: [tokenItem],
            forceReload: true,
            userWalletId: userWalletId.stringValue
        )

        _ = try? await expressAvailabilityProvider.expressAvailabilityUpdateState
            .first { state in
                if case .updating = state {
                    return false
                }
                return true
            }
            .async()
    }
}
