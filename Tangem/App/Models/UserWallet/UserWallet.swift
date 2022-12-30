//
//  UserWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk

struct UserWallet: Identifiable, Codable {
    var id = UUID()
    let userWalletId: Data
    var name: String
    var card: CardDTO
    var associatedCardIds: Set<String>
    let walletData: DefaultWalletData
    let artwork: ArtworkInfo?
    let isHDWalletAllowed: Bool
}

extension UserWallet {
    struct SensitiveInformation: Codable {
        let wallets: [Card.Wallet]
    }
}

extension UserWallet {
    var isLocked: Bool {
        card.wallets.isEmpty
    }

    func cardInfo() -> CardInfo {
        let cardArtwork: CardArtwork
        if let artwork = artwork {
            cardArtwork = .artwork(artwork)
        } else {
            cardArtwork = .noArtwork
        }

        return CardInfo(
            card: card,
            walletData: walletData,
            name: self.name,
            artwork: cardArtwork,
            primaryCard: nil
        )
    }
}
