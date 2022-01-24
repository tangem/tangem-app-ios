//
//  SavedCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SavedCard: Codable {
    let cardId: String
    let wallets: [SavedCardWallet]
    var derivedKeys: [Data: [SavedExtendedPublicKey]] = [:]
    
    func getDerivedKeys(for walletPublicKey: Data) -> [DerivationPath: ExtendedPublicKey] {
        guard let derived = derivedKeys[walletPublicKey] else { return [:] }

        let dict: [DerivationPath: ExtendedPublicKey] = derived.reduce(into: [:]) {
            $0[$1.derivationPath] = .init(publicKey: $1.compressedPublicKey,
                                          chainCode: $1.chainCode)
        }
        
        return dict
    }
    
    static func savedCard(from cardInfo: CardInfo) -> SavedCard {
        let wallets: [SavedCardWallet] = cardInfo.card.wallets.map {
            .init(publicKey: $0.publicKey, curve: $0.curve, chainCode: $0.chainCode)
        }
        
        let keys: [Data: [SavedExtendedPublicKey]] = cardInfo.derivedKeys.mapValues { derivations in
            return derivations.reduce(into: []) {
                $0.append(.init(from: $1.key, key: $1.value))
            }
        }
        
        return .init(cardId: cardInfo.card.cardId, wallets: wallets, derivedKeys: keys)
    }
}

struct SavedCardWallet: Codable {
    let publicKey: Data
    let curve: EllipticCurve
    let chainCode: Data?
    
    public var isHdWalletAllowed: Bool {  chainCode != nil }
}

struct SavedExtendedPublicKey: Codable {
    public let compressedPublicKey: Data
    public let chainCode: Data
    public let derivationPath: DerivationPath
    
    init(from derivationPath: DerivationPath, key: ExtendedPublicKey) {
        self.compressedPublicKey = key.publicKey
        self.chainCode = key.chainCode
        self.derivationPath = derivationPath
    }
}
