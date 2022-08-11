//
//  WalletModelBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

protocol WalletModelBuilder {
    var card: Card { get }

    func makeWalletModels() -> [WalletModel]
}

extension WalletModelBuilder {
    func makeWalletModels() -> [WalletModel] {
        let assembly = WalletManagerAssembly()
        let walletManagers = assembly.makeAllWalletManagers(for: cardInfo)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardInfo.card.derivationStyle,
                                isDemoCard: cardInfo.card.isDemoCard)
    }
}
