//
//  ExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressProviderManager {
    var pair: ExpressManagerSwappingPair { get }
    var feeProvider: ExpressFeeProvider { get }

    func getState() -> ExpressProviderManagerState

    func update(request: ExpressManagerSwappingPairRequest) async
    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData
}

public extension ExpressProviderManager {
    var isFeeCurrency: Bool { pair.source.currency == feeProvider.feeCurrency() }
}
