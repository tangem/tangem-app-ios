//
//  Card+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk
import CryptoKit

extension Card {
    var walletSignedHashes: Int {
        wallets.compactMap { $0.totalSignedHashes }.reduce(0, +)
    }

    var walletCurves: [EllipticCurve] {
        wallets.compactMap { $0.curve }
    }

    var hasWallets: Bool {
        !wallets.isEmpty
    }

    var derivationStyle: DerivationStyle? {
        Card.getDerivationStyle(for: batchId, isHdWalletAllowed: settings.isHDWalletAllowed)
    }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: cardId, cardPublicKey: cardPublicKey)
    }
    
    func userWalletId(walletData: DefaultWalletData?) -> Data {
        if !hasWallets {
            assertionFailure("Wallet not found, use CardViewModel for create wallet")
        }
        
        let key: Data
        switch walletData {
        case .twin(_, let twinData):
            guard let combinedKey = TwinCardsUtils.makeCombinedWalletKey(for: self, pairData: twinData) else {
                key = cardPublicKey
                break
            }
            
            key = combinedKey
        default:
            key = (wallets.first?.publicKey ?? cardPublicKey)
        }
        
        return UserWalletId(with: key).value
    }

    static func getDerivationStyle(for batchId: String, isHdWalletAllowed: Bool) -> DerivationStyle? {
        guard isHdWalletAllowed else {
            return nil
        }

        let batchId = batchId.uppercased()

        if BatchId.isDetached(batchId) {
            return .legacy
        }

        return .new
    }
}
