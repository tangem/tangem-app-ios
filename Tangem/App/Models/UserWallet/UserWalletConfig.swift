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

protocol UserWalletConfig: WalletConnectNetworkSelector {
    var emailConfig: EmailConfig { get }
    var touURL: URL? { get }
    var cardSetLabel: String? { get }
    var cardIdDisplayFormat: CardIdDisplayFormat { get }
    var features: Set<UserWalletFeature> { get }
    var defaultCurve: EllipticCurve? { get }

    var onboardingSteps: OnboardingSteps { get }
    var backupSteps: OnboardingSteps? { get }
    
    var disabledFeatureReason: String? { get }

    ///All blockchains supported by this user wallet.
    var supportedBlockchains: Set<Blockchain> { get }
    
    ///Blockchains to be added to the tokens list by default on wallet creation.
    var defaultBlockchains: [StorageEntry] { get }
    
    ///Blockchains to be added to the tokens list on every scan. E.g. demo blockchains.
    var persistentBlockchains: [StorageEntry]? { get }
    
    ///Blockchain which embedded in the card.
    var embeddedBlockchain: StorageEntry? { get }
    
    func selectBlockchain(for dAppInfo: Session.DAppInfo) -> BlockchainNetwork?
    
    func canUseFeature(_ feature: UserWalletFeature) -> Error?
}

protocol WalletConnectNetworkSelector {
    func selectBlockchain(for dAppInfo: Session.DAppInfo) -> BlockchainNetwork?
}

extension WalletConnectNetworkSelector {
    func selectBlockchain(for dAppInfo: Session.DAppInfo) -> BlockchainNetwork? {
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
