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

    private let card: Card
    private let walletData: WalletData

    init(card: Card, walletData: WalletData) {
        self.card = card
        self.walletData = walletData
    }

    private var defaultBlockchain: Blockchain {
        return Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    private var _backupSteps: [WalletOnboardingStep] {
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
}

extension SaltPayConfig: UserWalletConfig {
    var sdkConfig: Config {
        var config = Config()
        config.filter.allowedCardTypes = [.release, .sdk]
        config.logConfig = Log.Config.custom(logLevel: Log.Level.allCases,
                                             loggers: [loggerProvider.logger, ConsoleLogger()])
        config.filter.batchIdFilter = .deny(["0027",
                                             "0030",
                                             "0031",
                                             "0035"])

        config.filter.cardIdFilter = .allow(["AC03000000070529", "AC03000000070537"])

        config.filter.localizedDescription = "Это ошибка, которой пока нет"


        config.filter.issuerFilter = .deny(["TTM BANK"])
        config.allowUntrustedCards = true
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
            return .singleWallet([.createWallet, .success])
        }

        return .singleWallet([])
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
