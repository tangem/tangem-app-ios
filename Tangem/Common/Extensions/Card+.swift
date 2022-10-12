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
import CryptoKit
#endif

extension CardDTO {
    var walletSignedHashes: Int {
        wallets.compactMap { $0.totalSignedHashes }.reduce(0, +)
    }

    var walletCurves: [EllipticCurve] {
        wallets.compactMap { $0.curve }
    }

    #if !CLIP
    var hasWallets: Bool {
        !wallets.isEmpty
    }

    var userWalletId: Data {
        if !hasWallets {
            assertionFailure("Wallet not found, use CardViewModel for create wallet")
        }

        let keyHash = (wallets.first?.publicKey ?? cardPublicKey).sha256()
        let key = SymmetricKey(data: keyHash)
        let message = Constants.messageForWalletID.data(using: .utf8)!
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: message, using: key)

        return Data(authenticationCode)
    }

    var derivationStyle: DerivationStyle? {
        CardDTO.getDerivationStyle(for: batchId, isHdWalletAllowed: settings.isHDWalletAllowed)
    }

    var tangemApiAuthData: TangemApiTarget.AuthData {
        .init(cardId: cardId, cardPublicKey: cardPublicKey)
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

    #endif
}
