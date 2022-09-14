//
//  WalletManagerFactoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class WalletManagerFactoryProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager

    lazy var factory: WalletManagerFactory = {
        .init(config: keysManager.blockchainConfig)
    }()

    init() {}
}
