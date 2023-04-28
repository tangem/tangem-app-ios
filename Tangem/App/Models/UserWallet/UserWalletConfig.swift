//
//  UserWalletConfig.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

protocol UserWalletConfig {
    var sdkConfig: Config { get }

    var emailConfig: EmailConfig? { get }

    var tou: TOU { get }

    var cardsCount: Int { get }

    var cardSetLabel: String? { get }

    var cardName: String { get }

    var defaultCurve: EllipticCurve? { get }

    var tangemSigner: TangemSigner { get }

    var warningEvents: [WarningEvent] { get }

    var onboardingSteps: OnboardingSteps { get }

    var backupSteps: OnboardingSteps? { get }

    var canSkipBackup: Bool { get }

    /// All blockchains supported by this user wallet.
    var supportedBlockchains: Set<Blockchain> { get }

    /// Blockchains to be added to the tokens list by default on wallet creation.
    var defaultBlockchains: [StorageEntry] { get }

    /// Blockchains to be added to the tokens list on every scan. E.g. demo blockchains.
    var persistentBlockchains: [StorageEntry]? { get }

    /// Blockchain which embedded in the card.
    var embeddedBlockchain: StorageEntry? { get }

    var emailData: [EmailCollectedData] { get }

    var cardAmountType: Amount.AmountType? { get }

    var userWalletIdSeed: Data? { get }

    var supportChatEnvironment: SupportChatEnvironment { get }

    var exchangeServiceEnvironment: ExchangeServiceEnvironment { get }

    var productType: Analytics.ProductType { get }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability

    func makeWalletModel(for token: StorageEntry) throws -> WalletModel
}

extension UserWalletConfig {
    var sdkConfig: Config {
        TangemSdkConfigFactory().makeDefaultConfig()
    }

    var needUserWalletSavingSteps: Bool {
        return BiometricsUtil.isAvailable && !AppSettings.shared.saveUserWallets && !AppSettings.shared.askedToSaveUserWallets
    }

    func hasFeature(_ feature: UserWalletFeature) -> Bool {
        getFeatureAvailability(feature).isAvailable
    }

    var cardAmountType: Amount.AmountType? {
        return nil
    }

    var supportChatEnvironment: SupportChatEnvironment {
        .tangem
    }

    var exchangeServiceEnvironment: ExchangeServiceEnvironment {
        .default
    }

    var tou: TOU {
        let url = URL(string: "https://tangem.com/tangem_tos.html")!
        return TOU(id: url.absoluteString, url: url)
    }

    var emailConfig: EmailConfig? {
        .default
    }

    var canSkipBackup: Bool {
        true
    }
}

struct EmailConfig {
    let recipient: String
    let subject: String

    static var `default`: EmailConfig {
        .init(
            recipient: "support@tangem.com",
            subject: Localization.feedbackSubjectSupportTangem
        )
    }
}

struct TOU {
    let id: String
    let url: URL
}
