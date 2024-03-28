//
//  ExpressManagerMapper.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressManagerMapper {
    func makeExpressSwappableItem(
        request: ExpressManagerSwappingPairRequest,
        providerId: ExpressProvider.Id,
        providerType: ExpressProviderType
    ) -> ExpressSwappableItem {
        ExpressSwappableItem(
            source: request.pair.source,
            destination: request.pair.destination,
            amount: request.amount,
            providerInfo: .init(id: providerId, type: providerType)
        )
    }
}
