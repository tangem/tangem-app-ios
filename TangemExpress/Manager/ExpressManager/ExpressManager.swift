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
    func getAllProviders() -> [ExpressAvailableProvider]

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressAvailableProvider?
    func update(amount: Decimal?, by source: ExpressProviderUpdateSource) async throws -> ExpressAvailableProvider?
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressAvailableProvider
    func update(feeOption: ExpressFee.Option) async throws -> ExpressAvailableProvider
    func updateSelectedProvider(provider: ExpressAvailableProvider) async throws -> ExpressAvailableProvider
    func update(by source: ExpressProviderUpdateSource) async throws -> ExpressAvailableProvider?

    /// Use this method for CEX provider
    func requestData() async throws -> ExpressTransactionData
}
