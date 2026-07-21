//
//  CommonExpressRefundedTokenHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

class CommonExpressRefundedTokenHandler: ExpressRefundedTokenHandler {
    private let converter: ExpressCurrencyConverter

    init(converter: ExpressCurrencyConverter) {
        self.converter = converter
    }

    func handle(blockchainNetwork: BlockchainNetwork, expressCurrency: ExpressCurrency) async throws -> TokenItem {
        let tokenItem = try await converter.convert(
            expressCurrency: expressCurrency,
            in: blockchainNetwork
        )

        try TokenAdder.addToken(tokenItem: tokenItem)

        return tokenItem
    }
}
