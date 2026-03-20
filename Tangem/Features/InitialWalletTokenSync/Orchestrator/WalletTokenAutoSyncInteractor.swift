//
//  WalletTokenAutoSyncInteractor.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletTokenAutoSyncInteractor {
    func startIfPossible(userWalletModel: UserWalletModel, keyInfos: [KeyInfo]) async throws
}
