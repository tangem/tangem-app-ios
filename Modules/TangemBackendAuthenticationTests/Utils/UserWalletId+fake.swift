//
//  UserWalletId+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct Foundation.UUID
import struct TangemFoundation.UserWalletId

extension UserWalletId {
    static let fake = UserWalletId(value: Data([0x01, 0x02, 0x03]))

    static func uniqueFake() -> UserWalletId {
        UserWalletId(value: Data(UUID().uuidString.utf8))
    }
}
