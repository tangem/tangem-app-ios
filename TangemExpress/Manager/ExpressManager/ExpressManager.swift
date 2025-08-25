//
//  ExpressManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

public protocol ExpressManager: Actor {
    func getPair() -> ExpressManagerSwappingPair?
    func getAmount() -> Decimal?

    func update(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState
    func update(amount: Decimal?, by source: ExpressProviderUpdateSource) async throws -> ExpressManagerState
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState
    func update(feeOption: ExpressFee.Option) async throws -> ExpressManagerState

    func getAllProviders() -> [ExpressAvailableProvider]
    func getSelectedProvider() -> ExpressAvailableProvider?
    func updateSelectedProvider(provider: ExpressAvailableProvider) async throws -> ExpressManagerState

    func update(by source: ExpressProviderUpdateSource) async throws -> ExpressManagerState

    /// Use this method for CEX provider
    func requestData() async throws -> ExpressTransactionData
}
