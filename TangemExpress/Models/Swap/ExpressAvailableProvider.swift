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
    public var isBest: Bool
    public var isAvailable: Bool
    public let manager: ExpressProviderManager

    init(provider: ExpressProvider, isBest: Bool, isAvailable: Bool, manager: ExpressProviderManager) {
        self.provider = provider
        self.isBest = isBest
        self.isAvailable = isAvailable
        self.manager = manager
    }

    deinit {
        ExpressLogger.debug("deinit \(objectDescription(self))")
    }

    public func getState() -> ExpressProviderManagerState {
        manager.getState()
    }

    public func getPriority() -> Priority {
        guard isAvailable else {
            return .lowest
        }

        if isBest {
            return .highest
        }

        switch getState() {
        case .permissionRequired(let state):
            return .high(rate: state.quote.rate)
        case .preview(let state):
            return .high(rate: state.quote.rate)
        case .ready(let state):
            return .high(rate: state.quote.rate)
        case .restriction(.tooSmallAmount(let amount), _):
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

    func showableProviders(selectedProviderId: String?) -> [ExpressAvailableProvider] {
        filter { provider in
            guard provider.isAvailable else {
                return false
            }

            // If the provider `isSelected` we are forced to show it anyway
            let isSelected = selectedProviderId == provider.provider.id
            let isAvailableToShow = !provider.getState().isError

            return isSelected || isAvailableToShow
        }
    }
}

public extension ExpressAvailableProvider {
    enum Priority: Comparable {
        case lowest
        case low
        case medium(minimumAmount: Decimal)
        case high(rate: Decimal)
        case highest
    }
}
