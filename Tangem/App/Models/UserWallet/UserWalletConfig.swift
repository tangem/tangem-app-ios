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
import WalletConnectSwift

protocol UserWalletConfig {
    var emailConfig: EmailConfig { get }

    var touURL: URL? { get }

    var cardSetLabel: String? { get }

    var cardIdDisplayFormat: CardIdDisplayFormat { get }

    var defaultCurve: EllipticCurve? { get }

    var tangemSigner: TangemSigner { get }

    var warningEvents: [WarningEvent] { get }

    var onboardingSteps: OnboardingSteps { get }

    var backupSteps: OnboardingSteps? { get }

    /// All blockchains supported by this user wallet.
    var supportedBlockchains: Set<Blockchain> { get }

    /// Blockchains to be added to the tokens list by default on wallet creation.
    var defaultBlockchains: [StorageEntry] { get }

    /// Blockchains to be added to the tokens list on every scan. E.g. demo blockchains.
    var persistentBlockchains: [StorageEntry]? { get }

    /// Blockchain which embedded in the card.
    var embeddedBlockchain: StorageEntry? { get }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability

    func selectNetwork(for dAppInfo: Session.DAppInfo) -> BlockchainNetwork?

    //[REDACTED_TODO_COMMENT]
    func makeWalletModels(for tokens: [StorageEntry], derivedKeys: [DerivationPath: ExtendedPublicKey]) -> [WalletModel]
}

extension UserWalletConfig {
    func hasFeature(_ feature: UserWalletFeature) -> Bool {
        getFeatureAvailability(feature).isAvailable
    }

    func selectNetwork(for dAppInfo: Session.DAppInfo) -> BlockchainNetwork? {
        return nil
    }
}

struct EmailConfig {
    let recipient: String
    let subject: String

    static var `default`: EmailConfig {
        .init(recipient: "support@tangem.com",
              subject: "feedback_subject_support_tangem".localized)
    }
}

