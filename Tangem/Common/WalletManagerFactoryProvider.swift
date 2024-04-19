//
//  WalletManagerFactoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class WalletManagerFactoryProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.apiListProvider) private var apiOrderProvider: APIListProvider

    lazy var factory: WalletManagerFactory = .init(
        config: keysManager.blockchainConfig,
        dependencies: .init(
            accountCreator: BlockchainAccountCreator(),
            dataStorage: UserDefaultsBlockchainDataStorage(suiteName: AppEnvironment.current.blockchainDataStorageSuiteName)
        ),
        apiList: apiOrderProvider.apiList
    )

    init() {}
}
