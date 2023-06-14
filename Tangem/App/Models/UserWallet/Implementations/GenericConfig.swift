//
//  GenericConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct GenericConfig {
    let card: CardDTO

    init(card: CardDTO) {
        self.card = card
    }
}

extension GenericConfig: UserWalletConfig {
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
        [.secp256k1, .ed25519]
    }

    var canSkipBackup: Bool {
        card.firmwareVersion < .keysImportAvailable
    }

    var supportedBlockchains: Set<Blockchain> {
        let allBlockchains = AppEnvironment.current.isTestnet ? Blockchain.supportedTestnetBlockchains
            : Blockchain.supportedBlockchains

        return allBlockchains.filter { card.walletCurves.contains($0.curve) }
    }

    var defaultBlockchains: [StorageEntry] {
        if let persistentBlockchains = persistentBlockchains {
            return persistentBlockchains
        }

        let isTestnet = AppEnvironment.current.isTestnet
        let blockchains: [Blockchain] = [.ethereum(testnet: isTestnet), .bitcoin(testnet: isTestnet)]

        let entries: [StorageEntry] = blockchains.map {
            if let derivationStyle = card.derivationStyle {
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
        return nil
    }

    var embeddedBlockchain: StorageEntry? {
        return nil
    }

    var warningEvents: [WarningEvent] {
        var warnings = WarningEventsFactory().makeWarningEvents(for: card)

        if hasFeature(.hdWallets), card.derivationStyle == .legacy {
            warnings.append(.legacyDerivation)
        }

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
        card.firmwareVersion.doubleValue >= 4.39 ? .wallet : .other
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
            if card.firmwareVersion.doubleValue >= 4.52 {
                return .available
            }

            return .hidden
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
        case .seedPhrase:
            return card.settings.isKeysImportAllowed ? .available : .hidden
        case .accessCodeRecoverySettings:
            return card.firmwareVersion >= .keysImportAvailable ? .available : .hidden
        }
    }

    func makeWalletModel(for token: StorageEntry) throws -> WalletModel {
        let walletPublicKeys: [EllipticCurve: Data] = card.wallets.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.publicKey
        }

        let factory = WalletModelFactory()
        if card.settings.isHDWalletAllowed {
            let derivedKeys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]] = card.wallets.reduce(into: [:]) { partialResult, cardWallet in
                partialResult[cardWallet.curve] = cardWallet.derivedKeys
            }

            return try factory.makeMultipleWallet(
                seedKeys: walletPublicKeys,
                entry: token,
                derivedKeys: derivedKeys,
                derivationStyle: card.derivationStyle
            )
        } else {
            return try factory.makeMultipleWallet(
                walletPublicKeys: walletPublicKeys,
                entry: token,
                derivationStyle: card.derivationStyle
            )
        }
    }
}

// MARK: - WalletOnboardingStepsBuilderFactory

extension GenericConfig: WalletOnboardingStepsBuilderFactory {}

// MARK: - Private extensions

private extension Card.BackupStatus {
    var backupCardsCount: Int? {
        if case .active(let backupCards) = self {
            return backupCards
        }

        return nil
    }
}
