//
//  NoteConfigBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class NoteConfigBuilder: UserWalletConfigBuilder {
    private let card: Card
    private let noteData: WalletData

    private var onboardingSteps: [SingleCardOnboardingStep] {
        if card.wallets.isEmpty {
            return [.createWallet, .topup, .successTopup]
        } else {
            if !AppSettings.shared.cardsStartedActivation.contains(card.cardId) {
                return []
            }

            return [.topup, .successTopup]
        }
    }

    init(card: Card, noteData: WalletData) {
        self.card = card
        self.noteData = noteData
    }

    func buildConfig() -> UserWalletConfig {
        var features = baseFeatures(for: card)

        features.insert(.sendingToPayIDAllowed)
        features.insert(.exchangingAllowed)
        features.insert(.signedHashesCounterAvailable)
        features.insert(.activation)

        let blockchainName = noteData.blockchain.lowercased() == "binance" ? "bsc" : noteData.blockchain
        let defaultBlockchain = Blockchain.from(blockchainName: blockchainName, curve: .secp256k1)

        let config = UserWalletConfig(cardIdFormatted: AppCardIdFormatter(cid: card.cardId).formatted(),
                                      emailConfig: .default,
                                      touURL: nil,
                                      cardSetLabel: nil,
                                      cardIdDisplayFormat: .full,
                                      features: features,
                                      defaultBlockchain: defaultBlockchain,
                                      defaultToken: nil,
                                      onboardingSteps: .singleWallet(onboardingSteps),
                                      backupSteps: nil,
                                      defaultDisabledFeatureAlert: nil)
        return config
    }
}
