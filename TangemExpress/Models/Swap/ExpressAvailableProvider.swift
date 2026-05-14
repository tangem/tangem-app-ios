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
    public var isBest: Bool { _isBest.read() }

    private let _isBest: ThreadSafeContainer<Bool>

    init(provider: ExpressProvider, manager: ExpressProviderManager, supportedRateTypes: Set<ExpressProviderRateType>, isBest: Bool) {
        self.provider = provider
        self.manager = manager
        self.supportedRateTypes = supportedRateTypes

        _isBest = .init(isBest)
    }

    func update(isBest: Bool) {
        _isBest.mutate { $0 = isBest }
    }

    deinit {
        ExpressLogger.debug(self, "deinit")
    }

    public func getState() -> ExpressProviderManagerState {
        manager.getState()
    }

    public func getPriority() -> Priority {
        if isBest {
            return .highest
        }

        switch getState() {
        case .permissionRequired(let state), .revokeAndPermissionRequired(let state):
            return .high(rate: state.quote.rate)
        case .cexPreview(let state):
            return .high(rate: state.quote.rate)
        case .dexPreview(let state):
            return .high(rate: state.quote.rate)
        case .restriction(.tooSmallAmount(let amount, _), _):
            // HACK: We need to use a negative value here because
            // sorting by priority works from higher to lower.
            return .medium(minimumAmount: -amount)
        case .restriction:
            return .low
        case .idle, .error:
            return .lowest
        }
    }
}

// MARK: - CustomStringConvertible

extension ExpressAvailableProvider: CustomStringConvertible {
    public var description: String {
        objectDescription(self, userInfo: ["provider": provider.name])
    }
}

// MARK: - ExpressAvailableProvider + Priority

public extension ExpressAvailableProvider {
    enum Priority: Comparable {
        case lowest
        case low
        case medium(minimumAmount: Decimal)
        case high(rate: Decimal)
        case highest
    }
}

// MARK: - [ExpressAvailableProvider]+

public extension [ExpressAvailableProvider] {
    func sortedByPriorityAndQuotes() -> [ExpressAvailableProvider] {
        typealias SortableProvider = (priority: ExpressAvailableProvider.Priority, amount: Decimal)

        return sorted { lhsProvider, rhsProvider in
            let lhsPriority = lhsProvider.getPriority()
            let lhsExpectedAmount = lhsProvider.getState().quote?.expectAmount ?? 0

            let rhsPriority = rhsProvider.getPriority()
            let rhsExpectedAmount = rhsProvider.getState().quote?.expectAmount ?? 0

            if lhsPriority == rhsPriority {
                return lhsExpectedAmount > rhsExpectedAmount
            }

            return lhsPriority > rhsPriority
        }
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
