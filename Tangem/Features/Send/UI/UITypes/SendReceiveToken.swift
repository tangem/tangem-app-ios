//
//  SendReceiveToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import struct TangemUI.TokenIconInfo

struct SendReceiveToken: Hashable {
    let wallet: String
    let tokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let fiatItem: FiatItem
}
