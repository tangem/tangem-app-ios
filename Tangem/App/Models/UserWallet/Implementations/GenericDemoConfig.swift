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

struct GenericDemoConfig {
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding

    private let card: CardDTO

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

    init(card: CardDTO) {
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
        guard let backupCardsCount = card.backupStatus?.backupCardsCount else {
            return nil
        }

        return String.localizedStringWithFormat("card_label_card_count".localized, backupCardsCount + 1)
    }

    var cardsCount: Int {
        1
    }

    var defaultCurve: EllipticCurve? {
        return nil
    }

    var cardName: String {
        "Wallet"
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
        let blockchains = DemoUtil().getDemoBlockchains(isTestnet: card.isTestnet)

        let entries: [StorageEntry] = blockchains.map {
            let derivationPath = $0.derivationPath(for: card.derivationStyle)
            let network = BlockchainNetwork($0, derivationPath: derivationPath)
            return .init(blockchainNetwork: network, tokens: [])
        }

        return entries
    }

    var embeddedBlockchain: StorageEntry? {
        return nil
    }

    var warningEvents: [WarningEvent] {
        var warnings = WarningEventsFactory().makeWarningEvents(for: card)

        if card.isTestnet {
            warnings.append(.testnetCard)
        } else {
            warnings.append(.demoCard)
        }

        return warnings
    }

    var tangemSigner: TangemSigner {
        .init(with: card.cardId)
    }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: nil)
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
            return .hidden
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
            return .disabled(localizedReason: "alert_demo_feature_disabled".localized)
        case .twinning:
            return .hidden
        case .exchange:
            return .disabled(localizedReason: "alert_demo_feature_disabled".localized)
        case .walletConnect:
            return .disabled(localizedReason: "alert_demo_feature_disabled".localized)
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
        let model: WalletModel

        if card.settings.isHDWalletAllowed {
            let derivedKeys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]] = card.wallets.reduce(into: [:]) { partialResult, cardWallet in
                partialResult[cardWallet.curve] = cardWallet.derivedKeys
            }

            model = try factory.makeMultipleWallet(seedKeys: walletPublicKeys,
                                                   entry: token,
                                                   derivedKeys: derivedKeys,
                                                   derivationStyle: card.derivationStyle)
        } else {
            model = try factory.makeMultipleWallet(walletPublicKeys: walletPublicKeys,
                                                   entry: token,
                                                   derivationStyle: card.derivationStyle)
        }

        model.demoBalance = DemoUtil().getDemoBalance(for: model.wallet.blockchain)
        return model
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

fileprivate extension CardDTO {
    var isTestnet: Bool {
        if batchId == "99FF" {
            return cardId.starts(with: batchId.reversed())
        } else {
            return false
        }
    }
}
