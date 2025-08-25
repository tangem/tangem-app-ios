//
//  AddressResolverFactoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

class AddressResolverFactoryProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.apiListProvider) private var apiListProvider: APIListProvider

    /// It is safe to get provider list without validation that list is not empty, because this factory created
    /// only after WalletManager creation, which can't created without API list
    lazy var factory = AddressResolverFactory(
        blockchainSdkKeysConfig: keysManager.blockchainSdkKeysConfig,
        tangemProviderConfig: .ephemeralConfiguration,
        apiList: apiListProvider.apiList
    )
}
