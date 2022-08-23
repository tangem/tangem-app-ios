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
    let walletData: DefaultWalletData
    let artwork: ArtworkInfo?
    var keys: [Data: [DerivationPath: ExtendedPublicKey]] // encrypted
    let isHDWalletAllowed: Bool
}

extension UserWallet {
    struct SensitiveInformation: Codable {
        let keys: [Data: [DerivationPath: ExtendedPublicKey]]
        let wallets: [Card.Wallet]
    }
}

extension UserWallet {
    var isLocked: Bool {
        card.wallets.isEmpty
    }

    var encryptionKey: SymmetricKey? {
        guard let firstWalletPublicKey = card.wallets.first?.publicKey else { return nil }

        let keyHash = firstWalletPublicKey.getSha256()
        let key = SymmetricKey(data: keyHash)
        let message = "TokensSymmetricKey".data(using: .utf8)!
        let tokensSymmetricKey = HMAC<SHA256>.authenticationCode(for: message, using: key)
        let tokensSymmetricKeyData = Data(tokensSymmetricKey)

        return SymmetricKey(data: tokensSymmetricKeyData)
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
            derivedKeys: keys,
            primaryCard: nil
        )
    }
}
