//
//  Card+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import TangemSdk
import CryptoKit

#if !CLIP
import BlockchainSdk
#endif

extension CardDTO {
    var walletSignedHashes: Int {
        wallets.compactMap { $0.totalSignedHashes }.reduce(0, +)
    }

    var walletCurves: [EllipticCurve] {
        wallets.compactMap { $0.curve }
    }

    var userWalletId: Data {
        guard let firstWalletPublicKey = wallets.first?.publicKey else { return Data() }

        let keyHash = firstWalletPublicKey.getSha256()
        let key = SymmetricKey(data: keyHash)
        let message = "AccountID".data(using: .utf8)!
        let code = HMAC<SHA256>.authenticationCode(for: message, using: key)

        return Data(code)
    }

    #if !CLIP
    var derivationStyle: DerivationStyle {
        CardDTO.getDerivationStyle(for: batchId, isHdWalletAllowed: settings.isHDWalletAllowed)
    }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: cardId, cardPublicKey: cardPublicKey)
    }

    static func getDerivationStyle(for batchId: String, isHdWalletAllowed: Bool) -> DerivationStyle {
        guard isHdWalletAllowed else {
            return .legacy
        }

        let batchId = batchId.uppercased()

        if BatchId.isDetached(batchId) {
            return .legacy
        }

        return .new
    }

    #endif
}
