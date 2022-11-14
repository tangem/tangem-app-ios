//
//  UserWalletEncryptionKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

struct UserWalletEncryptionKey {
    let key: SymmetricKey

    init(publicKey: Data) {
        let keyHash = publicKey.getSha256()
        let key = SymmetricKey(data: keyHash)
        let message = Constants.messageForTokensKey.data(using: .utf8)!
        let tokensSymmetricKey = HMAC<SHA256>.authenticationCode(for: message, using: key)
        let tokensSymmetricKeyData = Data(tokensSymmetricKey)

        self.key = SymmetricKey(data: tokensSymmetricKeyData)
    }
}
