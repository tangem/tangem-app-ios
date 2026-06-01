//
//  ExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressProviderManager: AnyObject {
    func getState() -> ExpressProviderManagerState

    /// Resets the manager state to `.idle`. Used by `ExpressAvailableProvider` when there is
    /// nothing to quote (no amount, or the requested `rateType` is not supported).
    func reset()

    func update(request: ExpressManagerSwappingPairRequest) async
    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData
}
