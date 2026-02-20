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

public class ExpressManagerUpdatingResult {
    public let providers: [ExpressAvailableProvider]
    public let selected: ExpressAvailableProvider?

    init(providers: [ExpressAvailableProvider], selected: ExpressAvailableProvider?) {
        self.providers = providers
        self.selected = selected
    }
}

public extension ExpressManager {
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerUpdatingResult {
        let selected = try await update(pair: pair)
        let providers = getAllProviders()

        return ExpressManagerUpdatingResult(providers: providers, selected: selected)
    }

    func update(amount: Decimal?, by source: ExpressProviderUpdateSource) async throws -> ExpressManagerUpdatingResult {
        let selected = try await update(amount: amount, by: source)
        let providers = getAllProviders()

        return ExpressManagerUpdatingResult(providers: providers, selected: selected)
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerUpdatingResult {
        let selected = try await update(approvePolicy: approvePolicy)
        let providers = getAllProviders()

        return ExpressManagerUpdatingResult(providers: providers, selected: selected)
    }

    func update(feeOption: ExpressFee.Option) async throws -> ExpressManagerUpdatingResult {
        let selected = try await update(feeOption: feeOption)
        let providers = getAllProviders()

        return ExpressManagerUpdatingResult(providers: providers, selected: selected)
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async throws -> ExpressManagerUpdatingResult {
        let selected = try await updateSelectedProvider(provider: provider)
        let providers = getAllProviders()

        return ExpressManagerUpdatingResult(providers: providers, selected: selected)
    }

    func update(by source: ExpressProviderUpdateSource) async throws -> ExpressManagerUpdatingResult {
        let selected = try await update(by: source)
        let providers = getAllProviders()

        return ExpressManagerUpdatingResult(providers: providers, selected: selected)
    }
}
