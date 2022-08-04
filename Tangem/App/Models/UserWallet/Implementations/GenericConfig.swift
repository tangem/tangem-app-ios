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

    private var isDemoCard: Bool {
        DemoUtil().isDemoCard(cardId: card.cardId)
    }

    private var _backupSteps: [WalletOnboardingStep] {
        if !card.settings.isBackupAllowed {
            return []
        }

        var steps: [WalletOnboardingStep] = .init()

        steps.append(.backupIntro)

        if !backupServiceProvider.backupService.primaryCardIsSet {
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
        card.backupStatus?.backupCardsCount.map {
            .init(format: "card_label_number_format".localized, 1, $0 + 1)
        }
    }

    var cardIdDisplayFormat: CardIdDisplayFormat {
        .full
    }

    var features: Set<UserWalletConfig.Feature> {
        var features = Set<Feature>()
        features.insert(.sendingToPayIDAllowed)
        features.insert(.exchangingAllowed)
        features.insert(.walletConnectAllowed)
        features.insert(.manageTokensAllowed)
        features.insert(.activation)
        features.insert(.signingSupported)

        if card.settings.isBackupAllowed, card.backupStatus == .noBackup {
            features.insert(.backup)
        }

        if card.settings.isSettingPasscodeAllowed {
            features.insert(.settingAccessCodeAllowed)
        }

        if card.settings.isSettingPasscodeAllowed {
            features.insert(.settingPasscodeAllowed)
        }

        if card.firmwareVersion.doubleValue >= 4.52 {
            features.insert(.longHashesSupported)
        }

        return features
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
        guard isDemoCard else {
            return nil
        }

        let blockchains = DemoUtil().getDemoBlockchains(isTestnet: card.isTestnet)

        let entries: [StorageEntry] = blockchains.map {
            let derivationPath = $0.derivationPath(for: card.derivationStyle)
            let network = BlockchainNetwork($0, derivationPath: derivationPath)
            return .init(blockchainNetwork: network, tokens: [])
        }

        return entries
    }
}

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
