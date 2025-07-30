//
//  UserWalletEncryptionKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

public struct UserWalletEncryptionKey {
    public let symmetricKey: SymmetricKey

    public init(symmetricKey: SymmetricKey) {
        self.symmetricKey = symmetricKey
    }
}

public extension UserWalletEncryptionKey {
    init(userWalletIdSeed: Data) {
        let keyHash = Data(SHA512.hash(data: userWalletIdSeed))
        let key = SymmetricKey(data: keyHash)
        let message = Constants.messageForTokensKey.data(using: .utf8)!
        let tokensSymmetricKey = HMAC<SHA256>.authenticationCode(for: message, using: key)
        let tokensSymmetricKeyData = Data(tokensSymmetricKey)

        symmetricKey = SymmetricKey(data: tokensSymmetricKeyData)
    }
}

public extension UserWalletEncryptionKey {
    enum Constants {
        static let messageForTokensKey = "TokensSymmetricKey"
    }
}
