//
//  WalletManagerFactoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal

class WalletManagerFactoryProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager

    let apiList: APIList

    lazy var factory: WalletManagerFactory = .init(
        config: keysManager.blockchainConfig,
        dependencies: .init(
            accountCreator: BlockchainAccountCreator(),
            dataStorage: UserDefaultsBlockchainDataStorage(suiteName: AppEnvironment.current.blockchainDataStorageSuiteName)
        ),
        apiList: apiList
    )

    init(apiList: APIList) {
        self.apiList = apiList
    }
}
