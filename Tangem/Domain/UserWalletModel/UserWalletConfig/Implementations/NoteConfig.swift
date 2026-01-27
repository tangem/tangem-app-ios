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
import TangemAssets
import TangemFoundation
import TangemLocalization

struct NoteConfig: CardContainer {
    let card: CardDTO
    private let noteData: WalletData
    private let isDemo: Bool

    init(card: CardDTO, noteData: WalletData, isDemo: Bool) {
        self.card = card
        self.noteData = noteData
        self.isDemo = isDemo
    }

    private var defaultBlockchain: Blockchain {
        let blockchainName = noteData.blockchain.lowercased() == "binance" ? "bsc" : noteData.blockchain
        let defaultBlockchain = Blockchain.from(blockchainName: blockchainName, curve: .secp256k1)!
        return defaultBlockchain
    }
}

extension NoteConfig: UserWalletConfig {
    var cardsCount: Int {
        1
    }

    var defaultName: String {
        "Note"
    }

    var createWalletCurves: [EllipticCurve] {
        [defaultBlockchain.curve]
    }

    var supportedBlockchains: Set<Blockchain> {
        [defaultBlockchain]
    }

    var defaultBlockchains: [TokenItem] {
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
        let entry = TokenItem.blockchain(network)
        return [entry]
    }

    var persistentBlockchains: [TokenItem] {
        return defaultBlockchains
    }

    var embeddedBlockchain: TokenItem? {
        return defaultBlockchains.first
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        var notifications = GeneralNotificationEventsFactory().makeNotifications(for: card)

        if isDemo, !AppEnvironment.current.isTestnet {
            notifications.append(.demoCard)
        }

        return notifications
    }

    var emailData: [EmailCollectedData] {
        EmailDataFactory().makeEmailData(for: card, walletData: noteData)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        isDemo ? .demoNote : .note
    }

    var cardHeaderImage: ImageType? {
        switch defaultBlockchain {
        case .bitcoin: return Assets.Cards.noteBitcoin
        case .ethereum: return Assets.Cards.noteEthereum
        case .cardano: return Assets.Cards.noteCardano
        case .bsc: return Assets.Cards.noteBinance
        case .dogecoin: return Assets.Cards.noteDoge
        case .xrp: return Assets.Cards.noteXrp
        default: return nil
        }
    }

    var contextBuilder: WalletCreationContextBuilder {
        ["type": "card"]
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .hidden
        case .passcode:
            return .hidden
        case .longTap:
            if isDemo {
                return .hidden
            }

            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .signing:
            return .available
        case .longHashes:
            return .hidden
        case .backup:
            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            return isDemo ? .disabled(localizedReason: Localization.alertDemoFeatureDisabled) : .available
        case .walletConnect:
            return .hidden
        case .multiCurrency:
            return .hidden
        case .resetToFactory:
            return isDemo ? .disabled(localizedReason: Localization.alertDemoFeatureDisabled) : .available
        case .hdWallets:
            return .hidden
        case .staking:
            return .hidden
        case .referralProgram:
            return .hidden
        case .swapping:
            return .hidden
        case .displayHashesCount:
            return .available
        case .transactionHistory:
            return .hidden
        case .accessCodeRecoverySettings:
            return .hidden
        case .nft:
            return .hidden
        case .iCloudBackup:
            return .hidden
        case .mnemonicBackup:
            return .hidden
        case .userWalletAccessCode:
            return .hidden
        case .userWalletBackup:
            return .hidden
        case .isBalanceRestrictionActive:
            return .hidden
        case .userWalletUpgrade:
            return .hidden
        case .cardSettings:
            return .available
        case .nfcInteraction:
            return .available
        case .transactionPayloadLimit:
            return .available
        case .tangemPay:
            return .hidden
        }
    }

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> WalletModelsFactory {
        if isDemo {
            return DemoWalletModelsFactory(config: self, userWalletId: userWalletId)
        }

        return CommonWalletModelsFactory(config: self, userWalletId: userWalletId)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        return SimpleWalletManagerFactory()
    }
}

// MARK: - NoteCardOnboardingStepsBuilderFactory

extension NoteConfig: NoteCardOnboardingStepsBuilderFactory {}
