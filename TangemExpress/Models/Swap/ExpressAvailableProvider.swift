//
//  ExpressAvailableProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

public class ExpressAvailableProvider {
    private let context: ExpressProviderFlowContext
    private let manager: ExpressProviderManager
    public let rateType: ExpressProviderRateType

    public var provider: ExpressProvider { context.provider }
    public var pair: ExpressManagerSwappingPair { context.pair }
    public var expressFeeProvider: ExpressFeeProvider { context.expressFeeProvider }

    public var isBest: Bool { _isBest { $0 } }
    public var state: ExpressProviderManagerState { manager.getState() }

    // MARK: - Updatable state

    private let _isBest = OSAllocatedUnfairLock<Bool>(initialState: false)

    init(context: ExpressProviderFlowContext, manager: ExpressProviderManager, rateType: ExpressProviderRateType) {
        self.context = context
        self.manager = manager
        self.rateType = rateType
    }

    deinit {
        ExpressLogger.debug(self, "deinit")
    }
}

// MARK: - Internal

extension ExpressAvailableProvider {
    func update(isBest: Bool) {
        _isBest { $0 = isBest }
    }

    func updateState(request: ExpressManagerSwappingPairRequest) async {
        await manager.update(request: request)
    }

    func requestData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        return try await manager.sendData(request: request)
    }

    func reset() {
        manager.reset()
    }
}

// MARK: - Equatable

extension ExpressAvailableProvider: Equatable {
    public static func == (lhs: ExpressAvailableProvider, rhs: ExpressAvailableProvider) -> Bool {
        lhs === rhs
    }
}

// MARK: - CustomStringConvertible

extension ExpressAvailableProvider: CustomStringConvertible {
    public var description: String {
        objectDescription(self, userInfo: ["provider": provider.name])
    }
}

// MARK: - [ExpressAvailableProvider]+

public extension Array where Element == ExpressAvailableProvider {
    func sortedByAttractively() -> [ExpressAvailableProvider] {
        sorted(by: ExpressProviderManagerComparator.isBetter)
    }

    func best() -> ExpressAvailableProvider? {
        self.min(by: ExpressProviderManagerComparator.isBetter)
    }

    func showableProviders() -> [ExpressAvailableProvider] {
        filter { $0.state.isShowable }
    }

    func showableProviders(selectedProviderId: String?) -> [ExpressAvailableProvider] {
        filter { provider in
            // If the provider `isSelected` we are forced to show it anyway
            let isSelected = selectedProviderId == provider.provider.id
            let isAvailableToShow = provider.state.isShowable

            return isSelected || isAvailableToShow
        }
    }

    /// Recomputes `isBest` on every provider in the array.
    func updateIsBestFlag() {
        guard showableProviders().count > 1 else {
            forEach { $0.update(isBest: false) }
            return
        }

        let best = best()

        forEach { provider in
            switch provider {
            case best where provider.state.quote != nil:
                provider.update(isBest: true)
                provider.pair.source.analyticsLogger.bestProviderSelected(provider)
            default:
                provider.update(isBest: false)
            }
        }

        let providers = map(\.provider.name).joined(separator: ", ")
        ExpressLogger.info("Update providers \(providers). Best: \(best?.provider.name ?? "no best provider"))")
    }
}
