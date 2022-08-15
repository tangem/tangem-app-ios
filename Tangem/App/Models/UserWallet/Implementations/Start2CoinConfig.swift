//
//  Start2CoinConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct Start2CoinConfig {
    private let card: Card
    private let walletData: WalletData

    private var defaultBlockchain: Blockchain {
        Blockchain.from(blockchainName: walletData.blockchain, curve: card.supportedCurves[0])!
    }

    private func makeTouURL() -> URL? {
        let baseurl = "https://app.tangem.com/tou/"
        let regionCode = self.regionCode(for: card.cardId) ?? "fr"
        let languageCode = Locale.current.languageCode ?? "fr"
        let filename = self.filename(languageCode: languageCode, regionCode: regionCode)
        let url = URL(string: baseurl + filename)
        return url
    }

    private func filename(languageCode: String, regionCode: String) -> String {
        switch (languageCode, regionCode) {
        case ("fr", "ch"):
            return "Start2Coin-fr-ch-tangem.pdf"
        case ("de", "ch"):
            return "Start2Coin-de-ch-tangem.pdf"
        case ("en", "ch"):
            return "Start2Coin-en-ch-tangem.pdf"
        case ("it", "ch"):
            return "Start2Coin-it-ch-tangem.pdf"
        case ("fr", "fr"):
            return "Start2Coin-fr-fr-atangem.pdf"
        case ("de", "at"):
            return "Start2Coin-de-at-tangem.pdf"
        case (_, "fr"):
            return "Start2Coin-fr-fr-atangem.pdf"
        case (_, "ch"):
            return "Start2Coin-en-ch-tangem.pdf"
        case (_, "at"):
            return "Start2Coin-de-at-tangem.pdf"
        default:
            return "Start2Coin-fr-fr-atangem.pdf"
        }
    }

    private func regionCode(for cid: String) -> String? {
        let cidPrefix = cid[cid.index(cid.startIndex, offsetBy: 1)]
        switch cidPrefix {
        case "0":
            return "fr"
        case "1":
            return "ch"
        case "2":
            return "at"
        default:
            return nil
        }
    }

    init(card: Card, walletData: WalletData) {
        self.card = card
        self.walletData = walletData
    }
}

extension Start2CoinConfig: UserWalletConfig {
    var emailConfig: EmailConfig {
        .init(recipient: "cardsupport@start2coin.com",
              subject: "feedback_subject_support".localized)
    }

    var touURL: URL? {
        makeTouURL()
    }

    var cardSetLabel: String? {
        nil
    }

    var cardIdDisplayFormat: CardIdDisplayFormat {
        .full
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
        return nil
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
        WarningEventsFactory().makeWarningEvents(for: card)
    }

    var tangemSigner: TangemSigner { .init(with: card.cardId) }

    var emailData: [EmailCollectedData] {
        CardEmailDataFactory().makeEmailData(for: card, walletData: walletData)
    }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability {
        switch feature {
        case .signing:
            return .available
        case .signedHashesCounter:
            if card.firmwareVersion.type == .release {
                return .available
            }

            return .unavailable
        case .accessCode:
            return .unavailable
        case .passcode:
            return .unavailable
        case .longTap:
            return card.settings.isResettingUserCodesAllowed ? .available : .unavailable
        case .longHashes:
            return .unavailable
        case .backup:
            return .unavailable
        case .twinning:
            return .unavailable
        case .sendingToPayID:
            return .unavailable
        case .exchange:
            return .unavailable
        case .walletConnect:
            return .unavailable
        case .manageTokens:
            return .unavailable
        case .activation:
            return .unavailable
        case .tokensSearch:
            return .unavailable
        case .resetToFactory:
            return .unavailable
        case .showAddress:
            return .available
        case .withdrawal:
            return .available
        case .hdWallets:
            return .unavailable
        case .onlineImage:
            return card.firmwareVersion.type == .release ? .available : .unavailable
        }
    }

    func makeWalletModels(for tokens: [StorageEntry], derivedKeys: [Data: [DerivationPath: ExtendedPublicKey]]) -> [WalletModel] {
        guard let walletPublicKey = card.wallets.first(where: { $0.curve == defaultBlockchain.curve })?.publicKey else {
            return []
        }

        let factory = WalletModelFactory()

        if let model = factory.makeSingleWallet(walletPublicKey: walletPublicKey,
                                                blockchain: defaultBlockchain,
                                                token: nil,
                                                derivationStyle: card.derivationStyle) {
            return [model]
        }

        return []
    }
}
