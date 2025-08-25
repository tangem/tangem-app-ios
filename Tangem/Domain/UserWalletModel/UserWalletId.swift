//
//  UserWalletId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk

struct UserWalletId: Hashable {
    let value: Data
    let stringValue: String

    init(value: Data) {
        self.value = value
        stringValue = value.hexString
    }
}

extension UserWalletId {
    init(with walletPublicKey: Data) {
        let keyHash = walletPublicKey.getSha256()
        let key = SymmetricKey(data: keyHash)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: Constants.message, using: key)
        value = Data(authenticationCode)
        stringValue = value.hexString
    }

    init?(cardInfo: CardInfo) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        self.init(config: config)
    }

    init?(config: UserWalletConfig) {
        guard let seed = config.userWalletIdSeed else {
            return nil
        }

        self.init(with: seed)
    }
}

private extension UserWalletId {
    enum Constants {
        static let message = "UserWalletID".data(using: .utf8)!
    }
}
