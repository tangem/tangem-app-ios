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
    func getCurrentPair() async -> ExpressManagerSwappingPair?
    func getAmountType() async -> ExpressAmountType?

    /// Recreates providers. Does not update quotes.
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState

    /// Updates quotes for providers eligible for the current `ExpressAmountType`.
    func update(amountType: ExpressAmountType?) async -> ExpressManagerState

    /// Updates state (fee) for the selected provider with a new `ApprovePolicy`.
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState

    /// Preserves the selected provider across autoupdate cycles.
    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState

    /// Refreshes quotes for providers matching `rate` and optionally updates the selection.
    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState

    /// Use this method for CEX provider
    func requestData() async throws -> ExpressTransactionData
}

public enum ExpressManagerState {
    case idle

    @available(*, unavailable, message: "This is not implemented yet")
    case transfer

    case swap(selected: ExpressAvailableProvider?, providers: Providers)

    public struct Providers {
        public static let empty = Providers(float: [], fixed: [])

        public var isEmpty: Bool { all.isEmpty }

        public var supportedRateTypes: Set<ExpressProviderRateType> {
            all.map(\.rateType).toSet()
        }

        private let float: [ExpressAvailableProvider]
        private let fixed: [ExpressAvailableProvider]

        /// Internal — used only inside the module
        var all: [ExpressAvailableProvider] { float + fixed }

        init(float: [ExpressAvailableProvider], fixed: [ExpressAvailableProvider]) {
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
        switch self {
        case .idle:
            return objectDescription("ExpressManagerState", userInfo: ["mode": "idle"])
        case .swap(let selected, let providers):
            return objectDescription("ExpressManagerState", userInfo: [
                "mode": "swap",
                "selected name": selected.map { $0.provider.name } ?? "no selected provider",
                "selected state": selected.map { $0.getState() } ?? "no selected provider",
                "providers": providers.all.map { ($0.provider.name, $0.rateType.rawValue) },
                "allSupportedRateTypes": providers.supportedRateTypes,
            ])
        }
    }
}
