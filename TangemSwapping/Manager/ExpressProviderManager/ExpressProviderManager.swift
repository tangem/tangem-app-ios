//
//  ExpressProviderManager.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressProviderManager: Actor {
    func getState() -> ExpressProviderManagerState

    func update(request: ExpressManagerSwappingPairRequest, approvePolicy: ExpressApprovePolicy) async
    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData
}
