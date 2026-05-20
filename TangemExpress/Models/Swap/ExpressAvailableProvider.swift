//
//  ExpressAvailableProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public class ExpressAvailableProvider {
    public let provider: ExpressProvider
    public let manager: ExpressProviderManager
    public let supportedRateTypes: Set<ExpressProviderRateType>
    public var isBest: Bool { _isBest { $0 } }

    private let _isBest: OSAllocatedUnfairLock<Bool>

    init(provider: ExpressProvider, manager: ExpressProviderManager, supportedRateTypes: Set<ExpressProviderRateType>, isBest: Bool) {
        self.provider = provider
        self.manager = manager
        self.supportedRateTypes = supportedRateTypes

        _isBest = .init(initialState: isBest)
    }

    func update(isBest: Bool) {
        _isBest { $0 = isBest }
    }

    deinit {
        ExpressLogger.debug(self, "deinit")
    }

    public func getState() -> ExpressProviderManagerState {
        manager.getState()
    }
}

// MARK: - CustomStringConvertible

extension ExpressAvailableProvider: CustomStringConvertible {
    public var description: String {
        objectDescription(self, userInfo: ["provider": provider.name])
    }
}

// MARK: - [ExpressAvailableProvider]+

public extension [ExpressAvailableProvider] {
    func sortedByAttractively(rateType: ExpressProviderRateType) -> [ExpressAvailableProvider] {
        sorted { ExpressProviderManagerComparator.isBetter($0, $1, rateType: rateType) }
    }

    func best(rateType: ExpressProviderRateType) -> ExpressAvailableProvider? {
        self.min(by: { ExpressProviderManagerComparator.isBetter($0, $1, rateType: rateType) })
    }

    /// Sets `isBest` on the single best provider when there are 2+ ratable candidates
    /// (state carries a usable quote, not tooSmall/tooBig/error).
    /// Analytics is intentionally not fired here — call sites trigger `bestProviderSelected`
    /// only when selection actually changes (see `CommonExpressManager.updateSelectedProvider`).
    func updateIsBestFlag(rateType: ExpressProviderRateType) {
        let candidates = filter { provider in
            guard provider.supportedRateTypes.contains(rateType) else { return false }
            let state = provider.getState()
            switch state {
            case .error, .restriction(.tooSmallAmount, _), .restriction(.tooBigAmount, _):
                return false
            default:
                return state.quote != nil
            }
        }

        guard candidates.count > 1 else {
            forEach { $0.update(isBest: false) }
            return
        }

        let bestProvider = candidates.best(rateType: rateType)
        forEach { $0.update(isBest: $0 === bestProvider) }
    }

    func filteredByRateType(_ rateType: ExpressProviderRateType?) -> [ExpressAvailableProvider] {
        guard let rateType else {
            return self
        }

        return filter { $0.supportedRateTypes.contains(rateType) }
    }

    func showableProviders() -> [ExpressAvailableProvider] {
        filter { provider in
            let isAvailableToShow = !provider.getState().isError
            return isAvailableToShow
        }
    }

    func showableProviders(selectedProviderId: String?, rateType: ExpressProviderRateType? = nil) -> [ExpressAvailableProvider] {
        filter { provider in
            // If the provider `isSelected` we are forced to show it anyway
            let isSelected = selectedProviderId == provider.provider.id
            let isAvailableToShow = !provider.getState().isError
            let isSupportedRateType = rateType.map { provider.supportedRateTypes.contains($0) } ?? true

            return (isSelected || isAvailableToShow) && isSupportedRateType
        }
    }
}
