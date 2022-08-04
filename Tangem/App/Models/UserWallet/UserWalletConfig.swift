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
    var emailConfig: EmailConfig { get }
    var touURL: URL? { get }
    var cardSetLabel: String? { get }
    var cardIdDisplayFormat: CardIdDisplayFormat { get }
    var features: Set<UserWalletConfig.Feature> { get }

    var onboardingSteps: OnboardingSteps { get }
    var backupSteps: OnboardingSteps? { get }

    var supportedBlockchains: Set<Blockchain> { get }
    var defaultBlockchains: [StorageEntry] { get }
}

struct EmailConfig {
    let recipient: String
    let subject: String

    static var `default`: EmailConfig {
        .init(recipient: "support@tangem.com",
              subject: "feedback_subject_support_tangem".localized)
    }
}

struct UserWalletConfigFactory {
    private let cardInfo: CardInfo

    init(_ cardInfo: CardInfo) {
        self.cardInfo = cardInfo
    }

    func makeConfig() -> UserWalletConfig {
        switch cardInfo.walletData {
        case .none:
            return GenericConfig(card: cardInfo.card)
        case .note(let noteData):
            return NoteConfig(card: cardInfo.card, noteData: noteData)
        case .twin(let walletData, let twinData):
            return TwinConfig(card: cardInfo.card, walletData: walletData, twinData: twinData)
        case .v3(let walletData):
            if cardInfo.card.issuer.name.lowercased() == "start2coin" {
                return Start2CoinConfig(card: cardInfo.card, walletData: walletData)
            }

            return LegacyConfig(card: cardInfo.card, walletData: walletData)
        }
    }
}
