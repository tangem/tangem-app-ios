//
//  Wallet1Config.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemAssets
import TangemSdk
import BlockchainSdk
import TangemFoundation

struct Wallet1Config {
    let card: CardDTO
    private let isDemo: Bool

    init(card: CardDTO, isDemo: Bool) {
        self.card = card
        self.isDemo = isDemo
    }
}

extension Wallet1Config: UserWalletConfig {
    var cardsCount: Int {
        if let backupCardsCount = card.backupStatus?.backupCardsCount {
            return backupCardsCount + 1
        } else {
            return 1
        }
    }

    var defaultName: String {
        "Wallet"
    }

    var createWalletCurves: [EllipticCurve] {
        // Workaround for notes as demo multiwallets
        if isDemo, card.settings.maxWalletsCount == 1, let curve = card.supportedCurves.first {
            return [curve]
        }

        return [.secp256k1, .ed25519, .bls12381_G2_AUG]
    }

    var derivationStyle: DerivationStyle? {
        guard hasFeature(.hdWallets) else {
            return nil
        }

        let batchId = card.batchId.uppercased()
        if BatchId.isDetached(batchId) {
            return .v1
        }

        return .v2
    }

    var supportedBlockchains: Set<Blockchain> {
        SupportedBlockchains(version: .v1)
            .blockchains()
            .filter(supportedBlockchainFilter(for:))
    }

    var defaultBlockchains: [TokenItem] {
        if persistentBlockchains.isNotEmpty {
            return persistentBlockchains
        }

        let isTestnet = AppEnvironment.current.isTestnet
        let blockchains: [Blockchain] = [
            .bitcoin(testnet: isTestnet),
            .ethereum(testnet: isTestnet),
        ]

        let entries: [TokenItem] = blockchains.map {
            if let derivationStyle = derivationStyle {
                let derivationPath = $0.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork($0, derivationPath: derivationPath)
                return TokenItem.blockchain(network)
            }

            let network = BlockchainNetwork($0, derivationPath: nil)
            return TokenItem.blockchain(network)
        }

        return entries
    }

    var persistentBlockchains: [TokenItem] {
        guard isDemo else { return [] }

        let blockchainIds = DemoUtil().getDemoBlockchains(isTestnet: AppEnvironment.current.isTestnet)
            .filter { card.walletCurves.contains($0.curve) }
            .map { $0.coinId }

        let entries: [TokenItem] = blockchainIds.compactMap { coinId in
            guard let blockchain = supportedBlockchains.first(where: { $0.coinId == coinId }) else {
                return nil
            }

            if let derivationStyle = derivationStyle {
                let derivationPath = blockchain.derivationPath(for: derivationStyle)
                let network = BlockchainNetwork(blockchain, derivationPath: derivationPath)
                return TokenItem.blockchain(network)
            }

            let network = BlockchainNetwork(blockchain, derivationPath: nil)
            return TokenItem.blockchain(network)
        }

        return entries
    }

    var embeddedBlockchain: TokenItem? {
        return nil
    }

    var canSkipBackup: Bool {
        // Shiba cards have new firmware, but old config, except backup skipping.
        card.firmwareVersion < .keysImportAvailable
    }

    var generalNotificationEvents: [GeneralNotificationEvent] {
        var notifications = GeneralNotificationEventsFactory().makeNotifications(for: card)

        if hasFeature(.hdWallets), derivationStyle == .v1 {
            notifications.append(.legacyDerivation)
        }

        return notifications
    }

    var emailData: [EmailCollectedData] {
        EmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        if isDemo {
            return .demoWallet
        }

        return card.firmwareVersion.doubleValue >= 4.39 ? .wallet : .other
    }

    var cardHeaderImage: ImageType? {
        switch card.batchId {
        // Shiba cards
        case "AF02", "AF03":
            // There can't be more than 3 cards in single UserWallet
            switch cardsCount {
            case 2: return Assets.Cards.shibaDouble
            case 3: return Assets.Cards.shibaTriple
            default: return Assets.Cards.shibaSingle
            }
        default:
            // There can't be more than 3 cards in single UserWallet
            switch cardsCount {
            case 2: return Assets.Cards.walletDouble
            case 3: return Assets.Cards.walletTriple
            default: return Assets.Cards.walletSingle
            }
        }
    }

    var contextBuilder: WalletCreationContextBuilder {
        ["type": "card"]
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
        case .signing:
            return .available
        case .longHashes:
            if card.firmwareVersion.doubleValue >= 4.52 {
                return .available
            }

            return .hidden
        case .backup:
            if isDemo {
                return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
            }

            if card.settings.isBackupAllowed, card.backupStatus == .noBackup {
                return .available
            }

            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            if isDemo {
                return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
            }

            return .available
        case .walletConnect:
            if isDemo {
                return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
            }

            return .available
        case .multiCurrency:
            return .available
        case .resetToFactory:
            if isDemo {
                return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
            }

            return .available
        case .hdWallets:
            return card.settings.isHDWalletAllowed ? .available : .hidden
        case .staking:
            if isDemo {
                return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
            }

            return .available
        case .referralProgram:
            if isDemo {
                return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
            }

            return .available
        case .swapping:
            if isDemo {
                return .disabled(localizedReason: Localization.alertDemoFeatureDisabled)
            }

            return .available
        case .displayHashesCount:
            return .available
        case .transactionHistory:
            return .hidden
        case .accessCodeRecoverySettings:
            return .hidden
        case .nft:
            return .available
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
            return card.settings.isHDWalletAllowed ? .available : .hidden
        }
    }

    func makeWalletModelsFactory(userWalletId: UserWalletId) -> WalletModelsFactory {
        if isDemo {
            return DemoWalletModelsFactory(config: self, userWalletId: userWalletId)
        }

        return CommonWalletModelsFactory(config: self, userWalletId: userWalletId)
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

extension Wallet1Config: WalletOnboardingStepsBuilderFactory {}

// MARK: - Private extensions

private extension Wallet1Config {
    func supportedBlockchainFilter(for blockchain: Blockchain) -> Bool {
        if case .quai = blockchain {
            return hasFeature(.hdWallets)
        }

        return true
    }
}

private extension Card.BackupStatus {
    var backupCardsCount: Int? {
        if case .active(let backupCards) = self {
            return backupCards
        }

        return nil
    }
}
