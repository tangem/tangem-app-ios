//
//  Wallet2Config.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
struct Wallet2Config {
    let card: CardDTO
    private let isDemo: Bool
    private let isRing: Bool

    init(card: CardDTO, isDemo: Bool, isRing: Bool) {
        self.card = card
        self.isDemo = isDemo
        self.isRing = isRing
    }
}

extension Wallet2Config: UserWalletConfig {
    var cardSetLabel: String? {
        guard let backupCardsCount = card.backupStatus?.backupCardsCount else {
            return nil
        }

        return Localization.cardLabelCardCount(backupCardsCount + 1)
    }

    var cardsCount: Int {
        if let backupCardsCount = card.backupStatus?.backupCardsCount {
            return backupCardsCount + 1
        } else {
            return 1
        }
    }

    var cardName: String {
        "Wallet"
    }

    var createWalletCurves: [EllipticCurve] {
        [.secp256k1, .ed25519, .bls12381_G2_AUG, .bip0340, .ed25519_slip0010]
    }

    var derivationStyle: DerivationStyle? {
        return .v3
    }

    var canSkipBackup: Bool {
        if isDemo {
            return true
        }

        return false
    }

    var isWalletsCreated: Bool {
        // Temporary disable strict checking because of possible usecases with activated wallet2 cards with legacy apps
        // let validator = CurvesValidator(expectedCurves: createWalletCurves)

        /// It is allowed to skip backup In the case of demo cards and cards with `cardLinked` backup status .
        /// To handle cards with incorrectly created wallets in these cases, a check for backup status was added.
//        if card.backupStatus == .noBackup {
//            return validator.validate(card.walletCurves)
//        } else {
        return !card.wallets.isEmpty
//        }
    }

    var canImportKeys: Bool {
        card.settings.isKeysImportAllowed
    }

    var supportedBlockchains: Set<Blockchain> {
        SupportedBlockchains(version: .v2).blockchains()
    }

    var defaultBlockchains: [StorageEntry] {
        let isTestnet = AppEnvironment.current.isTestnet
        let blockchains: [Blockchain] = [
            .bitcoin(testnet: isTestnet),
            .ethereum(testnet: isTestnet),
        ]

        let entries: [StorageEntry] = blockchains.map {
            if let derivationStyle = derivationStyle {
                let derivationPath = $0.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork($0, derivationPath: derivationPath)
                return .init(blockchainNetwork: network, tokens: [])
            }

            let network = BlockchainNetwork($0, derivationPath: nil)
            return .init(blockchainNetwork: network, tokens: [])
        }

        return entries
    }

    var persistentBlockchains: [StorageEntry]? {
        guard isDemo else {
            return nil
        }

        let blockchainIds = DemoUtil().getDemoBlockchains(isTestnet: AppEnvironment.current.isTestnet)

        let entries: [StorageEntry] = blockchainIds.compactMap { coinId in
            guard let blockchain = supportedBlockchains.first(where: { $0.coinId == coinId }) else {
                return nil
            }

            if let derivationStyle = derivationStyle {
                let derivationPath = blockchain.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork(blockchain, derivationPath: derivationPath)
                return .init(blockchainNetwork: network, tokens: [])
            }

            let network = BlockchainNetwork(blockchain, derivationPath: nil)
            return .init(blockchainNetwork: network, tokens: [])
        }

        return entries
    }

    var embeddedBlockchain: StorageEntry? {
        return nil
    }

    var warningEvents: [WarningEvent] {
        var warnings = WarningEventsFactory().makeWarningEvents(for: card)

        if isDemo, !AppEnvironment.current.isTestnet {
            warnings.append(.demoCard)
        }

        return warnings
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        if isRing {
            return .ring
        }

        return .wallet2
    }

    var cardHeaderImage: ImageType? {
        if isRing {
            return nil
        }

        // Case with broken backup (e.g. CardLinked)
        if cardsCount == 1 {
            return nil
        }

        // Wallet 2.0 cards can't be used without backup, so min number of cards = 2
        // and there can't be more than 3 cards.
        switch card.batchId {
        // Tron 37X cards
        case "AF07":
            return cardsCount == 2 ? Assets.Cards.tronDouble : Assets.Cards.tronTriple
        // Kaspa cards
        case "AF08":
            return cardsCount == 2 ? Assets.Cards.kaspaDouble : Assets.Cards.kaspaTriple
        // BAD Idea cards
        case "AF09":
            return cardsCount == 2 ? Assets.Cards.badIdeaDouble : Assets.Cards.badIdeaTriple
        // Wallet white
        case "AF15":
            return cardsCount == 2 ? Assets.Cards.wallet2WhiteDouble : Assets.Cards.wallet2WhiteTriple
        // Wallet traillant
        case "AF16":
            return cardsCount == 2 ? Assets.Cards.walletTraillantDouble : Assets.Cards.walletTraillantTriple
        // Wallet avrora
        case "AF18":
            return cardsCount == 2 ? Assets.Cards.walletAvroraDouble : Assets.Cards.walletAvroraTriple
        // Wallet JR
        case "AF14":
            return cardsCount == 2 ? Assets.Cards.jrDouble : Assets.Cards.jrTriple
        // Wallet grim
        case "AF13":
            return cardsCount == 2 ? Assets.Cards.grimDouble : Assets.Cards.grimTriple
        // Wallet satoshi friends
        case "AF19":
            return cardsCount == 2 ? Assets.Cards.satoshiFriendsDouble : Assets.Cards.satoshiFriendsTriple
        // New World Elite (NWE)
        case "AF26":
            return cardsCount == 2 ? Assets.Cards.newWorldEliteDouble : Assets.Cards.newWorldEliteTriple
        // Vechain
        case "AF29":
            return cardsCount == 2 ? Assets.Cards.vechainWalletDouble : Assets.Cards.vechainWalletTriple
        // Pizza Day Wallet
        case "AF33":
            return cardsCount == 2 ? Assets.Cards.pizzaDayWalletDouble : Assets.Cards.pizzaDayWalletTriple
        // Red panda
        case "AF34":
            return cardsCount == 2 ? Assets.Cards.redPandaDouble : Assets.Cards.redPandaTriple
        // Cryptoseth
        case "AF32":
            return cardsCount == 2 ? Assets.Cards.cryptosethDouble : Assets.Cards.cryptosethTriple
        // Kishu
        case "AF52":
            return cardsCount == 2 ? Assets.Cards.kishuDouble : Assets.Cards.kishuTriple
        // Baby Doge
        case "AF51":
            return cardsCount == 2 ? Assets.Cards.babyDogeDouble : Assets.Cards.babyDogeTriple
        // TG-COQ
        case "AF28":
            return cardsCount == 2 ? Assets.Cards.tgDouble : Assets.Cards.tgTriple
        // Coin Metrica
        case "AF27":
            return cardsCount == 2 ? Assets.Cards.coinMetricaDouble : Assets.Cards.coinMetricaTriple
        // Volt Inu
        case "AF35":
            return cardsCount == 2 ? Assets.Cards.voltInuDouble : Assets.Cards.voltInuTriple
        // Kaspa 2
        case "AF25":
            return cardsCount == 2 ? Assets.Cards.kaspa2Double : Assets.Cards.kaspa2Triple
        // Kaspa reseller
        case "AF31":
            return cardsCount == 2 ? Assets.Cards.kaspaResellerDouble : Assets.Cards.kaspaResellerTriple
        // Lemon, Aqua, Grapefruit
        case "AF40", "AF41", "AF42":
            return Assets.Cards.lemonAquaGrapefruit
        // Peach, Air, Glass
        case "AF43", "AF44", "AF45":
            return Assets.Cards.peachAirGlass
        // Tangem Wallet 2.0
        default:
            return cardsCount == 2 ? Assets.Cards.wallet2Double : Assets.Cards.wallet2Triple
        }
    }

    var customOnboardingImage: ImageType? {
        if isRing {
            return Assets.ring
        }

        return nil
    }

    var customScanImage: ImageType? {
        if isRing {
            return Assets.ringShapeScan
        }

        return nil
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            if card.settings.isSettingAccessCodeAllowed {
                return .available
            }

            return .disabled()
        case .passcode:
            return .hidden
        case .longTap:
            return card.settings.isRemovingUserCodesAllowed ? .available : .hidden
        case .send:
            return .available
        case .longHashes:
            return .available
        case .signedHashesCounter:
            return .hidden
        case .backup:
            if isDemo {
                return .demoStub
            }

            if card.settings.isBackupAllowed, card.backupStatus == .noBackup {
                return .available
            }

            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            if isDemo {
                return .demoStub
            }

            return .available
        case .walletConnect:
            if isDemo {
                return .demoStub
            }

            return .available
        case .multiCurrency:
            return .available
        case .resetToFactory:
            if isDemo {
                return .demoStub
            }

            return .available
        case .receive:
            return .available
        case .withdrawal:
            return .available
        case .hdWallets:
            return card.settings.isHDWalletAllowed ? .available : .hidden
        case .onlineImage:
            return card.firmwareVersion.type == .release ? .available : .hidden
        case .staking:
            if card.firmwareVersion.doubleValue >= 4.52 {
                return .available
            }

            return .hidden
        case .topup:
            return .available
        case .tokenSynchronization:
            return .available
        case .referralProgram:
            if isDemo {
                return .demoStub
            }

            return .available
        case .swapping:
            if isDemo {
                return .demoStub
            }

            return .available
        case .displayHashesCount:
            return .available
        case .transactionHistory:
            return .hidden
        case .accessCodeRecoverySettings:
            return .available
        case .promotion:
            return .available
        }
    }

    func makeWalletModelsFactory() -> WalletModelsFactory {
        if isDemo {
            return DemoWalletModelsFactory(derivationStyle: derivationStyle)
        }

        return CommonWalletModelsFactory(derivationStyle: derivationStyle)
    }

    func makeAnyWalletManagerFactory() throws -> AnyWalletManagerFactory {
        if hasFeature(.hdWallets) {
            return GenericWalletManagerFactory()
        } else {
            return SimpleWalletManagerFactory()
        }
    }
}

// MARK: - WalletOnboardingStepsBuilderFactory

extension Wallet2Config: WalletOnboardingStepsBuilderFactory {}

// MARK: - Private extensions

private extension Card.BackupStatus {
    var backupCardsCount: Int? {
        if case .active(let backupCards) = self {
            return backupCards
        }

        return nil
    }
}

private extension CardDTO {
    var hasImportedWallets: Bool {
        wallets.contains(where: { $0.isImported == true })
    }
}
