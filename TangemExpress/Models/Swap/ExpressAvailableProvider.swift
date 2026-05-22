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

    public func getState() -> ExpressProviderManagerState {
        manager.getState()
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
        try await manager.sendData(request: request)
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
        filter { $0.getState().isShowable }
    }

    func showableProviders(selectedProviderId: String?) -> [ExpressAvailableProvider] {
        filter { provider in
            // If the provider `isSelected` we are forced to show it anyway
            let isSelected = selectedProviderId == provider.provider.id
            let isAvailableToShow = provider.getState().isShowable

            return isSelected || isAvailableToShow
        }
    }

    func updateIsBestFlag(activeRateType: ExpressProviderRateType?) {
        let candidates = filter { provider in
            guard provider.rateType == activeRateType else { return false }
            switch provider.getState() {
            case .permissionRequired, .revokeAndPermissionRequired, .cexPreview, .dexPreview:
                return provider.rateType == activeRateType
            case .idle, .error, .restriction:
                return false
            }
        }

        guard candidates.count > 1 else {
            forEach { $0.update(isBest: false) }
            return
        }

        let best = candidates.best()

        forEach { provider in
            provider.update(isBest: provider === best)
        }

        let providers = map(\.provider.name).joined(separator: ", ")
        ExpressLogger.info("Update providers \(providers). Best: \(best?.provider.name ?? "no best provider")")
    }
}
