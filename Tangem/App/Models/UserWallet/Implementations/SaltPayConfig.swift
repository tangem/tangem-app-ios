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

    init(card: Card) {
        self.card = card
        backupServiceProvider.backupService.skipCompatibilityChecks = true
    }

    private var defaultBlockchain: Blockchain {
        GnosisRegistrator.Settings.main.blockchain
    }

    private var defaultToken: Token {
        GnosisRegistrator.Settings.main.token
    }

    private var _backupSteps: [WalletOnboardingStep] {
        if let backupStatus = card.backupStatus, backupStatus.isActive,
           !backupServiceProvider.backupService.hasIncompletedBackup {
            return []
        }

        var steps: [WalletOnboardingStep] = .init()

        if !card.wallets.isEmpty && !backupServiceProvider.backupService.primaryCardIsSet {
            steps.append(.scanPrimaryCard)
        }

        if backupServiceProvider.backupService.addedBackupCardsCount < 1 {
            steps.append(.selectBackupCards)
        }

        steps.append(.backupCards)

        return steps
    }

    private var registrationSteps: [WalletOnboardingStep] {
        guard let registrator = saltPayRegistratorProvider.registrator else { return [] }

        var steps: [WalletOnboardingStep] = .init()

        switch registrator.state {
        case .needPin, .registration:
            steps.append(contentsOf: [.enterPin, .registerWallet, .kycStart, .kycProgress, .kycWaiting])
        case .kycRetry:
            steps.append(contentsOf: [.kycRetry, .kycProgress, .kycWaiting])
        case .kycStart:
            steps.append(contentsOf: [.kycStart, .kycProgress, .kycWaiting])
        case .kycWaiting:
            steps.append(contentsOf: [.kycWaiting])
        case .claim:
            break
        case .finished:
            if !AppSettings.shared.cardsStartedActivation.contains(card.cardId) {
                return []
            }
            return [.success]
        }

        if registrator.canClaim {
            steps.append(.claim)
            steps.append(.successClaim)
        } else {
            steps.append(.success)
        }

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
        config.filter.localizedDescription = "error_saltpay_wrong_backup_card".localized
        config.cardIdDisplayFormat = .none
        return config
    }

    var emailConfig: EmailConfig? {
        return nil
    }

    var touURL: URL {
        .init(string: "https://tangem.com/soltpay_tos.html")!
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
        if SaltPayUtil().isBackupCard(cardId: card.cardId) {
            return .wallet([])
        }

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
        let network = BlockchainNetwork(defaultBlockchain, derivationPath: nil)
        let entry = StorageEntry(blockchainNetwork: network, tokens: [defaultToken])
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
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
    }

    var cardAmountType: Amount.AmountType {
        .token(value: defaultToken)
    }

    var supportChatEnvironment: SupportChatEnvironment {
        .saltpay
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        .hidden
    }

    func makeWalletModel(for token: StorageEntry) throws -> WalletModel {
        let blockchain = token.blockchainNetwork.blockchain

        guard let walletPublicKey = card.wallets.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletModelFactory()
        return try factory.makeSingleWallet(walletPublicKey: walletPublicKey,
                                            blockchain: blockchain,
                                            token: token.tokens.first,
                                            derivationStyle: card.derivationStyle)
    }
}
