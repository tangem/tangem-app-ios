//
//  WalletTokenAutoSyncProgressService+Injected.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

private let sharedWalletTokenAutoSyncProgressService = CommonWalletTokenAutoSyncProgressService()

// MARK: - InjectionKey

private struct WalletTokenAutoSyncProgressServiceKey: InjectionKey {
    static var currentValue: WalletTokenAutoSyncProgressService = sharedWalletTokenAutoSyncProgressService
}

private struct WalletTokenAutoSyncProgressProviderKey: InjectionKey {
    static var currentValue: WalletTokenAutoSyncProgressProvider = sharedWalletTokenAutoSyncProgressService
}

// MARK: - InjectedValues

extension InjectedValues {
    var walletTokenSyncProgressService: WalletTokenAutoSyncProgressService {
        get { Self[WalletTokenAutoSyncProgressServiceKey.self] }
        set { Self[WalletTokenAutoSyncProgressServiceKey.self] = newValue }
    }

    var walletTokenSyncProgressProvider: WalletTokenAutoSyncProgressProvider {
        get { Self[WalletTokenAutoSyncProgressProviderKey.self] }
        set { Self[WalletTokenAutoSyncProgressProviderKey.self] = newValue }
    }
}
