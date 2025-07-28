//
//  WalletNetworkServiceFactoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class WalletNetworkServiceFactoryProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider

    lazy var factory = WalletNetworkServiceFactory(
        blockchainSdkKeysConfig: keysManager.blockchainSdkKeysConfig,
        tangemProviderConfig: .ephemeralConfiguration,
        apiList: apiListProvider.apiList
    )
}
