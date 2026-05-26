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
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState

    /// Updates quotes for providers eligible for the current `ExpressAmountType`.
    func update(amountType: ExpressAmountType?) async -> ExpressManagerState

    /// Updates state (fee) for the selected provider with a new `ApprovePolicy`.
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState

    /// Preserves the selected provider across autoupdate cycles.
    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState

    /// Refreshes quotes for the currently selected provider without changing the selection.
    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState

    /// Use this method for CEX provider
    func requestData() async throws -> ExpressTransactionData
}

public struct ExpressManagerState {
    public let rate: ExpressProviderRateType
    public let selected: ExpressAvailableProvider?
    public let providers: Providers

    public init(
        rate: ExpressProviderRateType = .float,
        selected: ExpressAvailableProvider? = nil,
        providers: Providers = Providers()
    ) {
        self.rate = rate
        self.selected = selected
        self.providers = providers
    }

    public struct Providers {
        public let float: [ExpressAvailableProvider]
        public let fixed: [ExpressAvailableProvider]

        public var all: [ExpressAvailableProvider] { float + fixed }

        public var supportedRateTypes: Set<ExpressProviderRateType> {
            all.map(\.rateType).toSet()
        }

        public init(float: [ExpressAvailableProvider] = [], fixed: [ExpressAvailableProvider] = []) {
            self.float = float
            self.fixed = fixed
        }

        public func availableProviders(rate: ExpressProviderRateType) -> [ExpressAvailableProvider] {
            switch rate {
            case .float: float
            case .fixed: fixed
            }
        }
    }
}

extension ExpressManagerState: CustomStringConvertible {
    public var description: String {
        objectDescription("ExpressManagerState", userInfo: [
            "rate": rate,
            "selected name": selected.map { $0.provider.name } ?? "no selected provider",
            "selected state": selected.map { $0.getState() } ?? "no selected provider",
            "providers": providers.all.map { $0.provider.name },
            "allSupportedRateTypes": providers.supportedRateTypes,
        ])
    }
}
