//
//  SendReceiveToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import struct TangemUI.TokenIconInfo

protocol SendReceiveToken {
    var tokenItem: TokenItem { get }
    var tokenIconInfo: TokenIconInfo { get }
    var fiatItem: FiatItem { get }
}

struct CommonSendReceiveToken: SendReceiveToken {
    let tokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let fiatItem: FiatItem
}
