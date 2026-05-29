//
//  ExpressProviderFlowContext.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct ExpressProviderFlowContext {
    let provider: ExpressProvider
    let pair: ExpressManagerSwappingPair
    let rateType: ExpressProviderRateType
    let expressFeeProvider: ExpressFeeProvider
    let expressAPIProvider: ExpressAPIProvider
    let mapper: ExpressManagerMapper
}
