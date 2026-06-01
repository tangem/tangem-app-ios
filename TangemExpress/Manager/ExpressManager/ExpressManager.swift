//
//  ExpressManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import BlockchainSdk

public protocol ExpressManager: Actor {
    func getAmountType() -> ExpressAmountType?
    func getRateType() -> ExpressProviderRateType?

    /// Recreates providers. Does not update quotes.
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerUpdatingResult

    /// Updates quotes for providers eligible for the current `ExpressAmountType`.
    func update(amountType: ExpressAmountType?) async -> ExpressManagerUpdatingResult

    /// Updates state (fee) for the selected provider with a new `ApprovePolicy`.
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerUpdatingResult

    /// Preserves the selected provider across autoupdate cycles.
    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerUpdatingResult

    /// Refreshes quotes for all available providers and changes the selection according to `type`.
    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerUpdatingResult

    /// Use this method for CEX provider
    func requestData() async throws -> ExpressTransactionData
}

public struct ExpressManagerUpdatingResult {
    public let providers: [ExpressAvailableProvider]
    public let selected: ExpressAvailableProvider?

    public init(providers: [ExpressAvailableProvider], selected: ExpressAvailableProvider?) {
        self.providers = providers
        self.selected = selected
    }
}

extension ExpressManagerUpdatingResult: CustomStringConvertible {
    public var description: String {
        objectDescription("ExpressManagerUpdatingResult", userInfo: [
            "selected name": selected.map { $0.provider.name } ?? "no selected provider",
            "selected state": selected.map { $0.getState() } ?? "no selected provider",
            "providers": providers.map { $0.provider.name },
        ])
    }
}
