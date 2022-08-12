//
//  TwinConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct TwinConfig: BaseConfig {
    private let card: Card
    private let walletData: WalletData
    private let twinData: TwinCardInfo

    private var defaultBlockchain: Blockchain {
        Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    private var isTestnet: Bool {
        defaultBlockchain.isTestnet
    }

    init(card: Card, walletData: WalletData, twinData: TwinCardInfo) {
        self.card = card
        self.walletData = walletData
        self.twinData = twinData
    }
}

extension TwinConfig: UserWalletConfig {
    var emailConfig: EmailConfig {
        .default
    }

    var touURL: URL? {
        nil
    }

    var cardSetLabel: String? {
        .init(format: "card_label_number_format".localized, twinData.series.number, 2)
    }

    var cardIdDisplayFormat: CardIdDisplayFormat {
        .lastLunh(4)
    }

    var defaultCurve: EllipticCurve? {
        defaultBlockchain.curve
    }

    var onboardingSteps: OnboardingSteps {
        var steps = [TwinsOnboardingStep]()

        if !AppSettings.shared.isTwinCardOnboardingWasDisplayed { // show intro only once
            AppSettings.shared.isTwinCardOnboardingWasDisplayed = true
            let twinPairCid = AppTwinCardIdFormatter.format(cid: "", cardNumber: twinData.series.pair.number)
            steps.append(.intro(pairNumber: "\(twinPairCid)"))
        }

        if card.wallets.isEmpty { // twin without created wallet. Start onboarding
            steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
            steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
            return .twins(steps)
        } else { // twin with created wallet
            if twinData.pairPublicKey == nil { // is not twinned
                steps.append(contentsOf: TwinsOnboardingStep.twinningProcessSteps)
                steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                return .twins(steps)
            } else { // is twinned
                if AppSettings.shared.cardsStartedActivation.contains(card.cardId) { // card is in onboarding process, go to topup
                    steps.append(contentsOf: TwinsOnboardingStep.topupSteps)
                    return .twins(steps)
                } else { // unknown twin, ready to use, go to main
                    return .twins(steps)
                }
            }
        }
    }

    var backupSteps: OnboardingSteps? {
        nil
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
        return nil
    }

    var embeddedBlockchain: StorageEntry? {
        return defaultBlockchains.first
    }

    var warningEvents: [WarningEvent] {
        var warnings = getBaseWarningEvents(for: card)

        if isTestnet {
            warnings.append(.testnetCard)
        }

        return warnings
    }

    // [REDACTED_TODO_COMMENT]
    var tangemSigner: TangemSigner { .init(with: card.cardId) }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .accessCode:
            return .unavailable
        case .passcode:
            if twinData.pairPublicKey != nil {
                return .available
            }

            return .disabled()
        case .signing:
            return .available
        case .longHashes:
            return .unavailable
        case .signedHashesCounter:
            return .unavailable
        case .backup:
            return .unavailable
        case .twinning:
            return .available
        case .sendingToPayID:
            return .available
        case .exchange:
            return .available
        case .walletConnect:
            return .unavailable
        case .manageTokens:
            return .unavailable
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

    func makeWalletModels(for tokens: [StorageEntry], derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]]) -> [WalletModel] {
        guard let savedPairKey = twinData.pairPublicKey,
              let walletPublicKey = card.wallets.first?.publicKey else {
            return []
        }

        do {
            let factory = WalletManagerFactoryProvider().factory
            let twinManager = try factory.makeTwinWalletManager(walletPublicKey: walletPublicKey,
                                                                pairKey: savedPairKey,
                                                                isTestnet: isTestnet)

            let model = WalletModel(walletManager: twinManager,
                                    derivationStyle: card.derivationStyle)

            model.initialize()
            return [model]
        } catch {
            print(error)
            return []
        }
    }
}
