//
//  PolymarketWalletInstanceCache.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class PolymarketWalletInstanceCache<Instance: AnyObject> {
    private let entries = OSAllocatedUnfairLock<[UserWalletId: Entry]>(uncheckedState: [:])

    func instance(for userWalletModel: any UserWalletModel, make: () -> Instance) -> Instance {
        let userWalletId = userWalletModel.userWalletId

        return entries.withLockUnchecked { entries in
            if let entry = entries[userWalletId], entry.owner === userWalletModel {
                return entry.instance
            }

            let instance = make()

            entries = entries.filter { $0.value.owner != nil }
            entries[userWalletId] = Entry(instance: instance, owner: userWalletModel)

            return instance
        }
    }

    func removeInstance(for userWalletId: UserWalletId) {
        entries.withLockUnchecked { _ = $0.removeValue(forKey: userWalletId) }
    }
}

// MARK: - Entry

private extension PolymarketWalletInstanceCache {
    struct Entry {
        let instance: Instance
        weak var owner: (any UserWalletModel)?
    }
}
