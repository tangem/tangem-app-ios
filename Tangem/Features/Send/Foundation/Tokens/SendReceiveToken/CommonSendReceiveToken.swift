//
//  CommonSendReceiveToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CommonSendReceiveToken: SendReceiveToken {
    let tokenItem: TokenItem
    let isCustom: Bool
    let fiatItem: FiatItem
    let address: String?
    let extraId: String?
}
