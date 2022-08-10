//
//  UserWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct UserWallet: Identifiable, Codable {
    var id = UUID()
    let userWalletId: Data
    var name: String
    let card: Card
    let walletData: DefaultWalletData
    let artwork: ArtworkInfo?
    let keys: [Data: [DerivationPath: ExtendedPublicKey]] // encrypted
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
