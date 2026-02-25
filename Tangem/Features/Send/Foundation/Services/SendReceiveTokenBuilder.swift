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
        let tokenIconInfo = tokenIconInfoBuilder.build(from: tokenItem, isCustom: false)

        return CommonSendReceiveToken(
            tokenItem: tokenItem,
            tokenIconInfo: tokenIconInfo,
            fiatItem: fiatItem,
            address: address,
            extraId: extraId
        )
    }
}
