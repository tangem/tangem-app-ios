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
    private let tokenLoader: TokenEnricher

    init(tokenLoader: any TokenEnricher) {
        self.tokenLoader = tokenLoader
    }

    func handle(blockchainNetwork: BlockchainNetwork, expressCurrency: ExpressCurrency) async throws -> TokenItem {
        let tokenItem = try await tokenLoader.enrichToken(
            blockchainNetwork: blockchainNetwork,
            contractAddress: expressCurrency.contractAddress
        )

        try TokenAdder.addToken(tokenItem: tokenItem)
        return tokenItem
    }
}
