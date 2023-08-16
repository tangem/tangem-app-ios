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

    init(card: CardDTO) {
        self.card = card
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

    var mandatoryCurves: [EllipticCurve] {
        [.secp256k1, .ed25519, .bip0340, .bls12381_G2_AUG, .ed25519_slip0010]
    }

    var derivationStyle: DerivationStyle? {
        assert(hasFeature(.hdWallets))

        // Keep in mind, that cards with hasImportedWallets == false must have old derivations
        if !card.hasImportedWallets {
            return .v2
        }

        return .v3
    }

    var canSkipBackup: Bool {
        return false
    }

    var canImportKeys: Bool {
        card.settings.isKeysImportAllowed && FeatureProvider.isAvailable(.importSeedPhrase)
    }

    var supportedBlockchains: Set<Blockchain> {
        let allBlockchains = SupportedBlockchains(version: .v2).blockchains()
        return allBlockchains.filter { card.walletCurves.contains($0.curve) }
    }

    var defaultBlockchains: [StorageEntry.V3.Entry] {
        let isTestnet = AppEnvironment.current.isTestnet
        let blockchains: [Blockchain] = [.ethereum(testnet: isTestnet), .bitcoin(testnet: isTestnet)]
        let converter = StorageEntriesConverter()

        return blockchains.map { blockchain in
            let network: BlockchainNetwork

            if let derivationStyle = derivationStyle {
                let derivationPath = blockchain.derivationPath(for: derivationStyle)
                network = BlockchainNetwork(blockchain, derivationPath: derivationPath)
            } else {
                network = BlockchainNetwork(blockchain, derivationPath: nil)
            }

            return converter.convert(network)
        }
    }

    var persistentBlockchains: [StorageEntry.V3.Entry]? {
        return nil
    }

    var embeddedBlockchains: [StorageEntry.V3.Entry]? {
        return nil
    }

    var warningEvents: [WarningEvent] {
        let warnings = WarningEventsFactory().makeWarningEvents(for: card)
        return warnings
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var tangemSigner: TangemSigner {
        let shouldSkipCardId = card.backupStatus?.isActive ?? false
        let cardId = shouldSkipCardId ? nil : card.cardId
        return .init(with: cardId, sdk: makeTangemSdk())
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var productType: Analytics.ProductType {
        .wallet2
    }

    var cardHeaderImage: ImageType? {
        cardsCount == 2 ? Assets.Cards.wallet2Double : Assets.Cards.wallet2Triple
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
            if card.settings.isBackupAllowed, card.backupStatus == .noBackup {
                return .available
            }

            return .hidden
        case .twinning:
            return .hidden
        case .exchange:
            return .available
        case .walletConnect:
            return .available
        case .multiCurrency:
            return .available
        case .resetToFactory:
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
            return .available
        case .topup:
            return .available
        case .tokenSynchronization:
            return .available
        case .referralProgram:
            return .available
        case .swapping:
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
        return CommonWalletModelsFactory(derivationStyle: derivationStyle)
    }

    func makeAnyWalletManagerFacrory() throws -> AnyWalletManagerFactory {
        if hasFeature(.hdWallets) {
            return HDWalletManagerFactory()
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
