//
//  UserWalletId+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct TangemFoundation.UserWalletId

extension UserWalletId {
    static let fake = UserWalletId(value: Data([0x01, 0x02, 0x03]))
}
