//
//  SaltPayConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

import Foundation
import TangemSdk
import BlockchainSdk

struct SaltPayConfig {
    private let card: CardDTO
    private let walletData: WalletData

    init(card: CardDTO, walletData: WalletData) {
        self.card = card
        self.walletData = walletData
    }

    private var defaultBlockchain: Blockchain {
        return Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }
}

extension SaltPayConfig: UserWalletConfig {
    var emailConfig: EmailConfig {
        .default
    }

    var touURL: URL? {
        nil
    }

    var cardsCount: Int {
        1
    }

    var cardSetLabel: String? {
        nil
    }

    var cardName: String {
        "Salt Pay"
    }

    var defaultCurve: EllipticCurve? {
        defaultBlockchain.curve
    }

    var onboardingSteps: OnboardingSteps {
        if card.wallets.isEmpty {
            return .singleWallet([.createWallet, .success])
        }

        return .singleWallet([])
    }

    var backupSteps: OnboardingSteps? {
        return nil
    }

    var supportedBlockchains: Set<Blockchain> {
        [defaultBlockchain]
    }

    var defaultBlockchains: [StorageEntry] {
        let derivationPath = defaultBlockchain.derivationPath(for: .legacy)
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: derivationPath)
        let entry = StorageEntry(blockchainNetwork: network, tokens: [])
        return [entry]
    }

    var persistentBlockchains: [StorageEntry]? {
        nil
    }

    var embeddedBlockchain: StorageEntry? {
        defaultBlockchains.first
    }

    var warningEvents: [WarningEvent] {
        WarningEventsFactory().makeWarningEvents(for: card)
    }

    var tangemSigner: TangemSigner { .init(with: card.cardId) }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: walletData)
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        .hidden
    }

    func makeWalletModel(for token: StorageEntry) throws -> WalletModel {
        guard let walletPublicKey = card.wallets.first(where: { $0.curve == defaultBlockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletModelFactory()
        return try factory.makeSingleWallet(walletPublicKey: walletPublicKey,
                                            blockchain: defaultBlockchain,
                                            token: nil,
                                            derivationStyle: card.derivationStyle)
    }
}
