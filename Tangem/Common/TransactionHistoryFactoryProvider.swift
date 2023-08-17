//
//  TransactionHistoryFactoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class TransactionHistoryFactoryProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager

    lazy var factory: TransactionHistoryProviderFactory = .init(config: keysManager.blockchainConfig)

    init() {}
}
