//
//  ExpressManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol ExpressManager: Actor {
    func getPair() -> ExpressManagerSwappingPair?
    func getAmountType() -> ExpressAmountType?
    func getRateType() -> ExpressProviderRateType?
    func getAllProviders() -> [ExpressAvailableProvider]

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerUpdatingResult
    func update(amountType: ExpressAmountType?, by source: ExpressProviderUpdateSource) async throws -> ExpressManagerUpdatingResult
    func update(by source: ExpressProviderUpdateSource) async throws -> ExpressManagerUpdatingResult

    /// Use this method for CEX provider
    func requestData() async throws -> ExpressTransactionData
}

public class ExpressManagerUpdatingResult {
    public let providers: [ExpressAvailableProvider]
    public let selected: ExpressAvailableProvider?

    public init(providers: [ExpressAvailableProvider], selected: ExpressAvailableProvider?) {
        self.providers = providers
        self.selected = selected
    }
}
