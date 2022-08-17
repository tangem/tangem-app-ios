//
//  NoteConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct NoteConfig {
    private let card: Card
    private let noteData: WalletData

    init(card: Card, noteData: WalletData) {
        self.card = card
        self.noteData = noteData
    }

    private var defaultBlockchain: Blockchain {
        let blockchainName = noteData.blockchain.lowercased() == "binance" ? "bsc" : noteData.blockchain
        let defaultBlockchain = Blockchain.from(blockchainName: blockchainName, curve: .secp256k1)!
        return defaultBlockchain
    }

    private var isTestnet: Bool {
        defaultBlockchain.isTestnet
    }
}

extension NoteConfig: UserWalletConfig {
    var emailConfig: EmailConfig {
        .default
    }

    var touURL: URL? {
        nil
    }

    var cardSetLabel: String? {
        nil
    }

    var cardsCount: Int {
        1
    }

    var defaultCurve: EllipticCurve? {
        defaultBlockchain.curve
    }

    var onboardingSteps: OnboardingSteps {
        if card.wallets.isEmpty {
            return .singleWallet([.createWallet, .topup, .successTopup])
        } else {
            if !AppSettings.shared.cardsStartedActivation.contains(card.cardId) {
                return .singleWallet([])
            }

            return .singleWallet([.topup, .successTopup])
        }
    }

    var backupSteps: OnboardingSteps? {
        nil
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
        return nil
    }

    var embeddedBlockchain: StorageEntry? {
        return defaultBlockchains.first
    }

    var warningEvents: [WarningEvent] {
        var warnings = WarningEventsFactory().makeWarningEvents(for: card)

        if isTestnet {
            warnings.append(.testnetCard)
        }

        return warnings
    }

    var tangemSigner: TangemSigner { .init(with: card.cardId) }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: noteData)
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .unavailable
        case .passcode:
            return .unavailable
        case .longTap:
            return card.settings.isResettingUserCodesAllowed ? .available : .unavailable
        case .send:
            return .available
        case .longHashes:
            return .unavailable
        case .signedHashesCounter:
            if card.firmwareVersion.type == .release {
                return .available
            }

            return .unavailable
        case .backup:
            return .unavailable
        case .twinning:
            return .unavailable
        case .exchange:
            return .available
        case .walletConnect:
            return .unavailable
        case .multiCurrency:
            return .unavailable
        case .tokensSearch:
            return .unavailable
        case .resetToFactory:
            return .available
        case .receive:
            return .available
        case .withdrawal:
            return .available
        case .hdWallets:
            return .unavailable
        case .onlineImage:
            return card.firmwareVersion.type == .release ? .available : .unavailable
        case .staking: return .available
        case .topup: return .available
        }
    }

    func makeWalletModels(for tokens: [StorageEntry], derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]]) -> [WalletModel] {
        guard let walletPublicKey = card.wallets.first(where: { $0.curve == defaultBlockchain.curve })?.publicKey else {
            return []
        }

        let factory = WalletModelFactory()

        if let model = factory.makeSingleWallet(walletPublicKey: walletPublicKey,
                                                blockchain: defaultBlockchain,
                                                token: nil,
                                                derivationStyle: card.derivationStyle) {
            return [model]
        }

        return []
    }
}
