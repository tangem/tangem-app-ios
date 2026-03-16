//
//  WalletTokenSyncStateActor.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor WalletTokenSyncStateActor {
    private var syncInProgress: Set<String> = []

    func tryRegister(userWalletId: UserWalletId) throws {
        let key = userWalletId.stringValue

        guard !syncInProgress.contains(key) else {
            throw WalletTokenAutoSyncError.syncAlreadyInProgress
        }

        syncInProgress.insert(key)
    }

    func unregister(userWalletId: UserWalletId) {
        syncInProgress.remove(userWalletId.stringValue)
    }
}
