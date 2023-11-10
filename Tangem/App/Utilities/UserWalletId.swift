//
//  UserWalletId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct UserWalletId: Hashable {
    let value: Data

    var stringValue: String { value.hexString }
}

extension UserWalletId {
    init(with walletPublicKey: Data) {
        value = PublicKeyId(walletPublicKey: walletPublicKey).value
    }
}
