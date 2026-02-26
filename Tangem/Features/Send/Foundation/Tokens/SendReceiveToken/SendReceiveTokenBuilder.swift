//
//  SendReceiveTokenBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct SendReceiveTokenBuilder {
    private let tokenIconInfoBuilder: TokenIconInfoBuilder
    private let fiatItem: FiatItem

    init(tokenIconInfoBuilder: TokenIconInfoBuilder, fiatItem: FiatItem) {
        self.tokenIconInfoBuilder = tokenIconInfoBuilder
        self.fiatItem = fiatItem
    }

    func makeSendReceiveToken(tokenItem: TokenItem, address: String? = nil, extraId: String? = nil) -> SendReceiveToken {
        return CommonSendReceiveToken(
            tokenItem: tokenItem,
            isCustom: false,
            fiatItem: fiatItem,
            address: address,
            extraId: extraId
        )
    }
}
