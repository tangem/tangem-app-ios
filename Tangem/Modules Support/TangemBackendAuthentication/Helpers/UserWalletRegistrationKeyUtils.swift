//
//  UserWalletRegistrationKeyUtils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import TangemSdk
import TangemMobileWalletSdk

enum UserWalletRegistrationKeyUtils {
    static func walletPublicKeyToRegister(in wallets: [Card.Wallet], cardId: String) throws(Error) -> Data {
        guard let wallet = wallets.first, let publicKey = wallet.publicKey else {
            throw .walletKeyUnavailable
        }

        return try secp256k1PublicKey(publicKey, curve: wallet.curve, cardId: cardId)
    }

    static func walletPublicKeyToRegister(in wallets: [MobileWalletKeyInfo]) throws(Error) -> Data {
        guard let wallet = wallets.first else {
            throw .walletKeyUnavailable
        }

        return try secp256k1PublicKey(wallet.publicKey, curve: wallet.curve, cardId: nil)
    }

    private static func secp256k1PublicKey(_ publicKey: Data, curve: EllipticCurve, cardId: String?) throws(Error) -> Data {
        guard curve == .secp256k1 else {
            var params: [Analytics.ParameterKey: String] = [:]
            params[.cardId] = cardId

            Analytics.log(event: .userWalletRegistrationUnexpectedCurve, params: params)

            throw .unexpectedCurve
        }

        return publicKey
    }
}

// MARK: - Error

extension UserWalletRegistrationKeyUtils {
    enum Error: Swift.Error {
        /// The user wallet has no keys yet, or its first key hasn't been read from the card.
        case walletKeyUnavailable

        /// The first key is not on the `secp256k1` curve, so it can't identify the user wallet.
        case unexpectedCurve
    }
}
