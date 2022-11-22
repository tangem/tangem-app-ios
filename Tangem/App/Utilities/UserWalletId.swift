//
//  UserWalletId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

struct UserWalletId {
    let value: Data

    var stringValue: String { value.hexString }

    init(with walletPublicKey: Data) {
        let keyHash = walletPublicKey.sha256()
        let key = SymmetricKey(data: keyHash)
        let message = Constants.messageForWalletID.data(using: .utf8)!
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: message, using: key)

        value = Data(authenticationCode)
    }
}
