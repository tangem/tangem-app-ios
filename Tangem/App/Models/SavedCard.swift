//
//  SavedCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct SavedCard: Codable { // [REDACTED_TODO_COMMENT]
    let cardId: String
    let batchId: String?
    let wallets: [SavedCardWallet]
    var derivedKeys: [Data: [SavedExtendedPublicKey]] = [:]

    private var derivationStyle: DerivationStyle {
        guard let batchId = batchId else {
            return .legacy
        }

        return Card.getDerivationStyle(for: batchId, isHdWalletAllowed: isHdWalletAllowed)
    }

    private var isHdWalletAllowed: Bool {
        wallets.contains { $0.isHdWalletAllowed }
    }

    func makeWalletModels(for tokens: [StorageEntry]) -> [WalletModel] {
        let walletPublicKeys: [EllipticCurve: Data] = wallets.reduce(into: [:]) { partialResult, cardWallet in
            partialResult[cardWallet.curve] = cardWallet.publicKey
        }

        let factory = WalletModelFactory()

        if isHdWalletAllowed {
            return factory.makeMultipleWallets(seedKeys: walletPublicKeys,
                                               entries: tokens,
                                               derivedKeys: getDerivedKeys(),
                                               derivationStyle: derivationStyle)
        } else {
            return factory.makeMultipleWallets(walletPublicKeys: walletPublicKeys,
                                               entries: tokens,
                                               derivationStyle: derivationStyle)
        }
    }

    private func getDerivedKeys() -> [EllipticCurve: [DerivationPath: ExtendedPublicKey]] {
        var keys: [EllipticCurve: [DerivationPath: ExtendedPublicKey]] = [:]

        for wallet in wallets {
            if let savedKeys = derivedKeys[wallet.publicKey] {
                var derivations: [DerivationPath: ExtendedPublicKey] = [:]

                for savedKey in savedKeys {
                    derivations[savedKey.derivationPath] = .init(publicKey: savedKey.compressedPublicKey,
                                                                 chainCode: savedKey.chainCode)
                }

                keys[wallet.curve] = derivations
            }
        }

        return keys
    }

    static func savedCard(from cardInfo: CardInfo) -> SavedCard {
        let wallets: [SavedCardWallet] = cardInfo.card.wallets.map {
            .init(publicKey: $0.publicKey, curve: $0.curve, chainCode: $0.chainCode)
        }


        var keys: [Data: [SavedExtendedPublicKey]] = [:]

        for wallet in cardInfo.card.wallets {
            let savedKeys: [SavedExtendedPublicKey] = wallet.derivedKeys.map {
                .init(from: $0.key, key: $0.value)
            }

            keys[wallet.publicKey] = savedKeys
        }

        return .init(cardId: cardInfo.card.cardId, batchId: cardInfo.card.batchId, wallets: wallets, derivedKeys: keys)
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
