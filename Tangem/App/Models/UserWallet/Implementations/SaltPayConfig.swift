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
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.loggerProvider) var loggerProvider: LoggerProviding
    @Injected(\.saletPayRegistratorProvider) private var saltPayRegistratorProvider: SaltPayRegistratorProviding

    private let card: Card
    private let walletData: WalletData

    init(card: Card, walletData: WalletData) {
        self.card = card
        self.walletData = walletData
        backupServiceProvider.backupService.skipCompatibilityChecks = true

        if let wallet = card.wallets.first {
            try? saltPayRegistratorProvider.initialize(cardId: card.cardId, walletPublicKey: wallet.publicKey, cardPublicKey: card.cardPublicKey)
        }
    }

    private var defaultBlockchain: Blockchain {
        return Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    private var _backupSteps: [WalletOnboardingStep] {
        if let backupStatus = card.backupStatus, backupStatus.isActive {
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

        return steps
    }

    private var registrationSteps: [WalletOnboardingStep] {
        guard let registrator = saltPayRegistratorProvider.registrator else { return [] }

        var steps: [WalletOnboardingStep] = .init()

        switch registrator.state {
        case .finished:
            if !AppSettings.shared.cardsStartedActivation.contains(card.cardId) {
                return []
            }
            break
        case .kycStart:
            steps.append(contentsOf: [.kycStart, .kycProgress, .kycWaiting])
        case .kycWaiting:
            steps.append(contentsOf: [.kycWaiting])
        case .needPin, .noGas, .registration:
            steps.append(contentsOf: [.enterPin, .registerWallet, .kycStart, .kycProgress, .kycWaiting])
        }

        steps.append(.success)
        return steps
    }
}

extension SaltPayConfig: UserWalletConfig {
    var sdkConfig: Config {
        var config = TangemSdkConfigFactory().makeDefaultConfig()
        let util = SaltPayUtil()

        var cardIds = util.backupCardIds
        cardIds.append(card.cardId)

        config.filter.cardIdFilter = .allow(Set(cardIds), ranges: util.backupCardRanges)

        // [REDACTED_TODO_COMMENT]
//        config.filter.localizedDescription = "Это ошибка, которой пока нет"
        return config
    }

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

    var defaultCurve: EllipticCurve? {
        defaultBlockchain.curve
    }

    var onboardingSteps: OnboardingSteps {
        if card.wallets.isEmpty {
            return .wallet([.createWallet] + _backupSteps + registrationSteps)
        } else {
            return .wallet(_backupSteps + registrationSteps)
        }
    }

    var backupSteps: OnboardingSteps? {
        return .wallet(_backupSteps)
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
