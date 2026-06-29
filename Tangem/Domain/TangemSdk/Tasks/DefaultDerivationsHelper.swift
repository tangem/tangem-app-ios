//
//  DefaultDerivationsHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//


import Foundation
import TangemSdk

struct DefaultDerivationsHelper {
    func makeDefaultDerivations(for card: Card) -> [EllipticCurve: [DerivationPath]] {
        let config = UserWalletConfigFactory().makeConfig(
            cardInfo: CardInfo(card: CardDTO(card: card), walletData: .none, associatedCardIds: [])
        )
       
        return makeDefaultDerivations(defaultBlockchains: config.defaultBlockchains)
    }
    
    func makeDefaultDerivations(defaultBlockchains: [TokenItem]) -> [EllipticCurve: [DerivationPath]] {
        let blockchainNetworks = defaultBlockchains.map { $0.blockchainNetwork }

        let derivations: [EllipticCurve: [DerivationPath]] = blockchainNetworks.reduce(into: [:]) { result, network in
            result[network.blockchain.curve, default: []].append(contentsOf: network.derivationPaths())
        }

       return derivations
    }
}
