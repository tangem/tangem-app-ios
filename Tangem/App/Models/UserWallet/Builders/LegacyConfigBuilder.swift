//
//  LegacyConfigBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class LegacyConfigBuilder: UserWalletConfigBuilder {
    private let card: Card
    private let walletData: WalletData

    private var onboardingSteps: [SingleCardOnboardingStep] {
        if card.wallets.isEmpty {
            return [.createWallet, .success]
        }
        
        return []
    }
    
    init(card: Card, walletData: WalletData) {
        self.card = card
        self.walletData = walletData
    }
    
    func buildConfig() -> UserWalletConfig {
        var features = baseFeatures(for: card)
        
        features.insert(.sendingToPayIDAllowed)
        features.insert(.exchangingAllowed)
        
        if card.supportedCurves.contains(.secp256k1) {
            features.insert(.walletConnectAllowed)
            features.insert(.manageTokensAllowed)
            features.insert(.tokensSearch)
        } else {
            features.insert(.signedHashesCounterAvailable)
        }

        let defaultBlockchain = Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])
        
        let defaultToken: BlockchainSdk.Token? = walletData.token.map {
            .init(name: $0.name, symbol: $0.symbol, contractAddress: $0.contractAddress, decimalCount: $0.decimals)
        }
        
        let config = UserWalletConfig(cardIdFormatted: AppCardIdFormatter(cid: card.cardId).formatted(),
                                      emailConfig: .default,
                                      touURL: nil,
                                      cardSetLabel: nil,
                                      cardIdDisplayFormat: .full,
                                      features: features,
                                      defaultBlockchain: defaultBlockchain,
                                      defaultToken: defaultToken,
                                      onboardingSteps: .singleWallet(onboardingSteps),
                                      backupSteps: nil,
                                      defaultDisabledFeatureAlert: nil)
        return config
    }
}
