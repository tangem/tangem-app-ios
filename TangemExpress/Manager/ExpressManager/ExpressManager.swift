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
    func getPair() -> ExpressManagerSwappingPair?
    func getAmountType() -> ExpressAmountType?
    func getRateType() -> ExpressProviderRateType?
    func getAllProviders() -> [ExpressAvailableProvider]

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerUpdatingResult
    func update(amountType: ExpressAmountType?, by source: ExpressProviderUpdateSource) async throws -> ExpressManagerUpdatingResult
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerUpdatingResult
    func updateSelectedProvider(provider: ExpressAvailableProvider) async throws -> ExpressManagerUpdatingResult
    func update(by source: ExpressProviderUpdateSource) async throws -> ExpressManagerUpdatingResult

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
            "providers": providers.map { $0.provider.name },
            "selected name": selected.map { $0.provider.name } ?? "no selected provider",
            "selected state": selected.map { $0.getState() } ?? "no selected provider",
        ])
    }
}
