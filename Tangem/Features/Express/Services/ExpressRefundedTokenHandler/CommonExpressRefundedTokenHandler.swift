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
    private let tokenEnricher: TokenEnricher

    init(tokenEnricher: any TokenEnricher) {
        self.tokenEnricher = tokenEnricher
    }

    func handle(blockchainNetwork: BlockchainNetwork, expressCurrency: ExpressCurrency) async throws -> TokenItem {
        let tokenItem = try await tokenEnricher.enrichToken(
            blockchainNetwork: blockchainNetwork,
            contractAddress: expressCurrency.contractAddress
        )

        try TokenAdder.addToken(tokenItem: tokenItem)
        return tokenItem
    }
}
