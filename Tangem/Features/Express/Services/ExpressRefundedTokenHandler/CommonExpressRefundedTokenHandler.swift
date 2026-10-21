//
//  CommonExpressRefundedTokenHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

class CommonExpressRefundedTokenHandler: ExpressRefundedTokenHandler {
    private let converter: ExpressCurrencyConverter

    init(converter: ExpressCurrencyConverter) {
        self.converter = converter
    }

    func handle(userWalletId: UserWalletId?, blockchainNetwork: BlockchainNetwork, expressCurrency: ExpressCurrency) async throws -> TokenItem {
        let tokenItem = try await converter.convert(
            expressCurrency: expressCurrency,
            in: blockchainNetwork
        )

        if let userWalletId {
            do {
                try TokenAdder.addToken(tokenItem: tokenItem, userWalletId: userWalletId)
            } catch {
                ExpressLogger.error("Failed to add the refunded token to the source wallet", error: error)
            }
        }

        return tokenItem
    }
}
