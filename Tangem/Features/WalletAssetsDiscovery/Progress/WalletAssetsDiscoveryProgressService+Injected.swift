//
//  WalletAssetsDiscoveryProgressService+Injected.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

private let sharedWalletAssetsDiscoveryProgressService = CommonWalletAssetsDiscoveryProgressService()

// MARK: - InjectionKey

private struct WalletAssetsDiscoveryProgressServiceKey: InjectionKey {
    static var currentValue: WalletAssetsDiscoveryProgressService = sharedWalletAssetsDiscoveryProgressService
}

private struct WalletAssetsDiscoveryProgressProviderKey: InjectionKey {
    static var currentValue: WalletAssetsDiscoveryProgressProvider = sharedWalletAssetsDiscoveryProgressService
}

// MARK: - InjectedValues

extension InjectedValues {
    var walletAssetsDiscoveryProgressService: WalletAssetsDiscoveryProgressService {
        get { Self[WalletAssetsDiscoveryProgressServiceKey.self] }
        set { Self[WalletAssetsDiscoveryProgressServiceKey.self] = newValue }
    }

    var walletAssetsDiscoveryProgressProvider: WalletAssetsDiscoveryProgressProvider {
        get { Self[WalletAssetsDiscoveryProgressProviderKey.self] }
        set { Self[WalletAssetsDiscoveryProgressProviderKey.self] = newValue }
    }
}
