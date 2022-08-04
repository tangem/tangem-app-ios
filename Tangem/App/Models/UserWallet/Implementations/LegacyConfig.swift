//
//  LegacyConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

/// V3 Config
struct LegacyConfig {
    private let card: Card
    private let walletData: WalletData

    private var defaultBlockchain: Blockchain {
        return Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    private var defaultToken: BlockchainSdk.Token? {
        if let token = walletData.token {
            return .init(name: token.name,
                         symbol: token.symbol,
                         contractAddress: token.contractAddress,
                         decimalCount: token.decimals)
        }
    }

    init(card: Card, walletData: WalletData) {
        self.card = card
        self.walletData = walletData
    }
}

extension LegacyConfig: UserWalletConfig {
    var emailConfig: EmailConfig {
        .default
    }

    var touURL: URL? {
        nil
    }

    var cardSetLabel: String? {
        nil
    }

    var cardIdDisplayFormat: CardIdDisplayFormat {
        .full
    }

    var features: Set<UserWalletConfig.Feature> {
        var features = Set<Feature>()
        features.insert(.sendingToPayIDAllowed)
        features.insert(.exchangingAllowed)

        if card.supportedCurves.contains(.secp256k1) {
            features.insert(.walletConnectAllowed)
            features.insert(.manageTokensAllowed)
            features.insert(.tokensSearch)
        } else {
            features.insert(.signedHashesCounterAvailable)
        }

        if card.firmwareVersion.doubleValue >= 2.28
            || card.settings.securityDelay <= 15000 {
            features.insert(.signingSupported)
        }

        return features
    }

    var defaultCurve: EllipticCurve? {
        defaultBlockchain?.curve
    }

    var onboardingSteps: OnboardingSteps {
        if card.wallets.isEmpty {
            return .singleWallet([.createWallet, .success])
        }

        return .singleWallet([])
    }

    var backupSteps: OnboardingSteps? {
        nil
    }

    var supportedBlockchains: Set<Blockchain> {
        if features.contains(.manageTokensAllowed) {
            let allBlockchains = defaultBlockchain.isTestnet ? Blockchain.supportedTestnetBlockchains
                : Blockchain.supportedBlockchains

            return allBlockchains.filter { card.supportedCurves.contains($0.curve) }
        } else {
            return [defaultBlockchain]
        }
    }

    var defaultBlockchains: [StorageEntry] {
        let derivationPath = defaultBlockchain.derivationPath(for: .legacy)
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: derivationPath)
        let tokens = defaultToken.map { [$0] } ?? []
        let entry = StorageEntry(blockchainNetwork: network, tokens: tokens)
        return [entry]
    }

    var persistentBlockchains: [StorageEntry]? {
        return nil
    }
}
