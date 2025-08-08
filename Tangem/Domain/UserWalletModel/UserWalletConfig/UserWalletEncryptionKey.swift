//
//  UserWalletEncryptionKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemFoundation

extension UserWalletEncryptionKey {
    init?(config: UserWalletConfig) {
        guard let seed = config.userWalletIdSeed else { return nil }

        self.init(userWalletIdSeed: seed)
    }
}
