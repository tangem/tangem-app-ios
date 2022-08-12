//
//  GenericDemoConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import WalletConnectSwift

struct GenericDemoConfig: BaseConfig, WalletModelBuilder {
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding

    private let card: Card

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

extension GenericDemoConfig: UserWalletConfig {
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
        var warnings = getBaseWarningEvents(for: card)

        if card.isTestnet {
            warnings.append(.testnetCard)
        } else {
            warnings.append(.demoCard)
        }

        return warnings
    }

    func selectBlockchain(for dAppInfo: Session.DAppInfo) -> BlockchainNetwork? {
        guard hasFeature(.walletConnect) else { return nil }

        guard let blockchain = WalletConnectNetworkParserUtility.parse(dAppInfo: dAppInfo,
                                                                       isTestnet: card.isTestnet) else {
            return nil
        }

        let derivationPath = blockchain.derivationPath(for: card.derivationStyle)
        let network = BlockchainNetwork(blockchain, derivationPath: derivationPath)
        return network
    }

    var tangemSigner: TangemSigner {
        .init(with: card.cardId)
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
        case .signing:
            return .available
        case .longHashes:
            if card.firmwareVersion.doubleValue >= 4.52 {
                return .available
            }

            return .unavailable
        case .signedHashesCounter:
            return .unavailable
        case .backup:
            return .disabled(localizedReason: "alert_demo_feature_disabled".localized)
        case .twinning:
            return .unavailable
        case .sendingToPayID:
            return .available
        case .exchange:
            return .disabled(localizedReason: "alert_demo_feature_disabled".localized)
        case .walletConnect:
            return .disabled(localizedReason: "alert_demo_feature_disabled".localized)
        case .manageTokens:
            return .available
        case .activation:
            return .available
        case .tokensSearch:
            return .unavailable
        case .resetToFactory:
            return .available
        case .showAddress:
            return .available
        case .withdrawal:
            return .available
        }
    }

    func makeWalletModels(for tokens: [StorageEntry], derivedKeys: [DerivationPath: ExtendedPublicKey]) -> [WalletModel] {
        var models: [WalletModel] = []

        if card.settings.isHDWalletAllowed {
            models = makeMultipleWallets(entries: tokens, derivedKeys: derivedKeys)
        } else {
            models = makeMultipleWallets(entries: tokens)
        }

        for model in models {
            model.demoBalance = DemoUtil().getDemoBalance(for: model.wallet.blockchain)
        }

        return models
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
