//
//  TwinsWalletCreationServiceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class TwinsWalletCreationServiceProvider: TwinsWalletCreationServiceProviding {
    @Injected(\.keysManager) private var keysManager: KeysManager

    lazy var service: TwinsWalletCreationService = {
        .init(twinFileEncoder: TwinCardTlvFileEncoder(),
              walletManagerFactory: WalletManagerFactory(config: keysManager.blockchainConfig))
    }()
}
