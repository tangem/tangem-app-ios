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
    /// Recreates providers. Does not update quotes.
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerUpdatingResult

    /// Updates quotes for providers eligible for the current `ExpressAmountType`.
    func update(amountType: ExpressAmountType?) async -> ExpressManagerUpdatingResult

    /// Updates state (fee) for the selected provider with a new `ApprovePolicy`.
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerUpdatingResult

    /// Preserves the selected provider across autoupdate cycles.
    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerUpdatingResult

    /// Refreshes quotes for the currently selected provider without changing the selection.
    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerUpdatingResult

    /// Use this method for CEX provider
    func requestData() async throws -> ExpressTransactionData
}

public struct ExpressManagerUpdatingResult {
    public let providers: [ExpressAvailableProvider]
    public let selected: ExpressAvailableProvider?
    public let supportedRateTypes: Set<ExpressProviderRateType>

    public init(
        providers: [ExpressAvailableProvider],
        selected: ExpressAvailableProvider?,
        supportedRateTypes: Set<ExpressProviderRateType>
    ) {
        self.providers = providers
        self.selected = selected
        self.supportedRateTypes = supportedRateTypes
    }
}

extension ExpressManagerUpdatingResult: CustomStringConvertible {
    public var description: String {
        objectDescription("ExpressManagerUpdatingResult", userInfo: [
            "selected name": selected.map { $0.provider.name } ?? "no selected provider",
            "selected state": selected.map { $0.getState() } ?? "no selected provider",
            "providers": providers.map { $0.provider.name },
            "allSupportedRateTypes": supportedRateTypes,
        ])
    }
}
