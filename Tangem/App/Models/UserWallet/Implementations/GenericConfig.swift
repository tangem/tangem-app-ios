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
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding

    private let card: Card

    private var _backupSteps: [WalletOnboardingStep] {
        if !card.settings.isBackupAllowed {
            return []
        }

        var steps: [WalletOnboardingStep] = .init()

        steps.append(.backupIntro)

        if !card.wallets.isEmpty && !backupServiceProvider.backupService.primaryCardIsSet {
            steps.append(.scanPrimaryCard)
        }

        if backupServiceProvider.backupService.addedBackupCardsCount < BackupService.maxBackupCardsCount {
            steps.append(.selectBackupCards)
        }

        steps.append(.backupCards)
        steps.append(.success)

        return steps
    }

    init(card: Card) {
        self.card = card
    }
}

extension GenericConfig: UserWalletConfig {
    var emailConfig: EmailConfig {
        .default
    }

    var touURL: URL? {
        nil
    }

    var cardSetLabel: String? {
        String.localizedStringWithFormat("card_label_card_count".localized, cardsCount + 1)
    }

    var cardsCount: Int {
        card.backupStatus?.backupCardsCount ?? 1
    }

    var defaultCurve: EllipticCurve? {
        return nil
    }

    var onboardingSteps: OnboardingSteps {
        if card.wallets.isEmpty {
            return .wallet([.createWallet] + _backupSteps)
        } else {
            if !AppSettings.shared.cardsStartedActivation.contains(card.cardId) {
                return .wallet([])
            }

            return .wallet(_backupSteps)
        }
    }

    var backupSteps: OnboardingSteps? {
        .wallet(_backupSteps)
    }

    var supportedBlockchains: Set<Blockchain> {
        let allBlockchains = card.isTestnet ? Blockchain.supportedTestnetBlockchains
            : Blockchain.supportedBlockchains

        return allBlockchains.filter { card.supportedCurves.contains($0.curve) }
    }

    var defaultBlockchains: [StorageEntry] {
        if let persistentBlockchains = self.persistentBlockchains {
            return persistentBlockchains
        }

        let blockchains: [Blockchain] = [.ethereum(testnet: card.isTestnet), .bitcoin(testnet: card.isTestnet)]

        let entries: [StorageEntry] = blockchains.map {
            let derivationPath = $0.derivationPath(for: card.derivationStyle)
            let network = BlockchainNetwork($0, derivationPath: derivationPath)
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

        if card.isTestnet {
            warnings.append(.testnetCard)
        }

        if hasFeature(.hdWallets) && card.derivationStyle == .legacy {
            warnings.append(.legacyDerivation)
        }

        return warnings
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var tangemSigner: TangemSigner {
        if let backupStatus = card.backupStatus, backupStatus.isActive {
            return .init(with: nil)
        } else {
            return .init(with: card.cardId)
        }
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            if card.settings.isSettingAccessCodeAllowed {
                return .available
            }

            return .disabled()
        case .passcode:
            if card.settings.isSettingPasscodeAllowed {
                return .available
            }

            return .disabled()
        case .longTap:
            return card.settings.isResettingUserCodesAllowed ? .available : .hidden
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

            return .disabled()
        case .twinning:
            return .hidden
        case .exchange:
            return .available
        case .walletConnect:
            return .available
        case .multiCurrency:
            return .available
        case .tokensSearch:
            return .hidden
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

            return try factory.makeMultipleWallet(seedKeys: walletPublicKeys,
                                                  entry: token,
                                                  derivedKeys: derivedKeys,
                                                  derivationStyle: card.derivationStyle)
        } else {
            return try factory.makeMultipleWallet(walletPublicKeys: walletPublicKeys,
                                                  entry: token,
                                                  derivationStyle: card.derivationStyle)
        }
    }
}


// MARK: - Private extensions

fileprivate extension Card.BackupStatus {
    var backupCardsCount: Int? {
        if case let .active(backupCards) = self {
            return backupCards
        }

        return nil
    }
}

fileprivate extension Card {
    var isTestnet: Bool {
        if batchId == "99FF" {
            return cardId.starts(with: batchId.reversed())
        } else {
            return false
        }
    }
}
