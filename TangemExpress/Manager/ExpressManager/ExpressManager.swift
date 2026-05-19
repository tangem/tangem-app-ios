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
    /// Recreates providers. Not update quotes
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerUpdatingResult

    /// Update quotes in providers which eligible for current `ExpressAmountType`
    func update(amountType: ExpressAmountType?) async -> ExpressManagerUpdatingResult

    /// Update state (fee) for selected provider with new `ApprovePolicy`.
    /// Not used now. Need to be discussed
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerUpdatingResult

    /// Update `ExpressManager._selectedProvider`. Need for not to lose selected provider when autoupdating
    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerUpdatingResult

    /// Refactor to autoupdate only.
    func autoupdate(source: ExpressProviderUpdateSource) async -> ExpressManagerUpdatingResult

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
            "providers": providers.map { $0.provider.name },
            "selected name": selected.map { $0.provider.name } ?? "no selected provider",
            "selected state": selected.map { $0.state } ?? "no selected provider",
            "supportedRateTypes": supportedRateTypes,
        ])
    }
}
