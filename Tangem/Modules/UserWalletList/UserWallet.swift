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
    var card: Card
    let walletData: DefaultWalletData
    let artwork: ArtworkInfo?
    var keys: [Data: [DerivationPath: ExtendedPublicKey]] // encrypted
    let isHDWalletAllowed: Bool
}

enum DefaultWalletData: Codable {
    case note(WalletData)
    case v3(WalletData)
    case twin(TwinData)
    case none
}

struct TwinData: Codable {
    let cardId: String
    var pairPublicKey: Data?
}

extension UserWallet {
    struct SensitiveInformation: Codable {
        let keys: [Data: [DerivationPath: ExtendedPublicKey]]
        let wallets: [Card.Wallet]
    }
}

extension UserWallet {
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
        let cardInfoWalletData: WalletData?
        if case let .note(wd) = walletData {
            cardInfoWalletData = wd
        } else {
            cardInfoWalletData = nil
        }
        return CardInfo(
            card: card,
            name: self.name,
            walletData: cardInfoWalletData,
            artwork: artwork == nil ? .noArtwork : .artwork(artwork!),
            twinCardInfo: nil,
            isTangemNote: isTangemNote,
            isTangemWallet: isTangemWallet,
            derivedKeys: keys,
            primaryCard: nil
        )
    }
}

extension UserWallet {
    var isTangemNote: Bool {
        if case .note = walletData {
            return true
        } else {
            return false
        }
    }

    var isTangemWallet: Bool {
        !isTangemNote
    }
}

extension UserWallet {
    var isMultiCurrency: Bool {
        if case .note = self.walletData {
            return false
        } else {
            return true
        }
    }
}
