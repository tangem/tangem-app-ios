//
//  SaltPayConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct SaltPayConfig {
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.saltPayRegistratorProvider) private var saltPayRegistratorProvider: SaltPayRegistratorProviding

    private let card: CardDTO

    init(card: CardDTO) {
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

        if !card.wallets.isEmpty, !backupServiceProvider.backupService.primaryCardIsSet {
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
            steps.append(contentsOf: [.enterPin, .registerWallet])

            if registrator.needsKYC {
                steps.append(contentsOf: [.kycStart, .kycProgress, .kycWaiting])
            }

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

        if !_backupSteps.isEmpty { // This filter should be applied to backup only.
            config.filter.cardIdFilter = .allow(Set(cardIds), ranges: util.backupCardRanges)
            config.filter.localizedDescription = Localization.errorSaltpayWrongBackupCard
        }
        config.cardIdDisplayFormat = .none
        return config
    }

    var emailConfig: EmailConfig? {
        return nil
    }

    var tou: TOU {
        let url = URL(string: "https://tangem.com/soltpay_tos.html")!
        return TOU(id: url.absoluteString, url: url)
    }

    var cardsCount: Int {
        1
    }

    var cardSetLabel: String? {
        nil
    }

    var cardName: String {
        "SaltPay"
    }

    var defaultCurve: EllipticCurve? {
        defaultBlockchain.curve
    }

    var onboardingSteps: OnboardingSteps {
        var steps = [WalletOnboardingStep]()

        if !AppSettings.shared.termsOfServicesAccepted.contains(tou.id) {
            steps.append(.disclaimer)
        }

        if SaltPayUtil().isBackupCard(cardId: card.cardId) {
            steps.append(contentsOf: userWalletSavingSteps)
        } else {
            if card.wallets.isEmpty {
                steps.append(contentsOf: [.createWallet] + _backupSteps + userWalletSavingSteps + registrationSteps)
            } else {
                steps.append(contentsOf: _backupSteps + userWalletSavingSteps + registrationSteps)
            }
        }

        return .wallet(steps)
    }

    var backupSteps: OnboardingSteps? {
        return .wallet(_backupSteps)
    }

    var canSkipBackup: Bool {
        false
    }

    var userWalletSavingSteps: [WalletOnboardingStep] {
        guard needUserWalletSavingSteps else { return [] }
        return [.saveUserWallet]
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
        defaultBlockchains
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

    var cardAmountType: Amount.AmountType? {
        .token(value: defaultToken)
    }

    var supportChatEnvironment: SupportChatEnvironment {
        .saltPay
    }

    var userWalletIdSeed: Data? {
        card.wallets.first?.publicKey
    }

    var exchangeServiceEnvironment: ExchangeServiceEnvironment {
        .saltpay
    }

    var productType: Analytics.ProductType {
        SaltPayUtil().isBackupCard(cardId: card.cardId) ? .visaBackup : .visa
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .transactionHistory:
            return .available
        default:
            return .hidden
        }
    }

    func makeWalletModel(for token: StorageEntry) throws -> WalletModel {
        let blockchain = token.blockchainNetwork.blockchain

        guard let walletPublicKey = card.wallets.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletModelFactory()
        return try factory.makeSingleWallet(
            walletPublicKey: walletPublicKey,
            blockchain: blockchain,
            token: token.tokens.first,
            derivationStyle: card.derivationStyle
        )
    }
}
