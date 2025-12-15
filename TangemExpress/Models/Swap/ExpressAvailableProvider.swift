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

    public func getState() async -> ExpressProviderManagerState {
        await manager.getState()
    }

    public func getPriority() async -> Priority {
        guard isAvailable else {
            return .lowest
        }

        if isBest {
            return .highest
        }

        switch await getState() {
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
    func sortedByPriorityAndQuotes() async -> [ExpressAvailableProvider] {
        typealias SortableProvider = (priority: ExpressAvailableProvider.Priority, amount: Decimal)

        return await asyncSorted(
            sort: { (lhsProvider: SortableProvider, rhsProvider: SortableProvider) in
                if lhsProvider.priority == rhsProvider.priority {
                    return lhsProvider.amount > rhsProvider.amount
                }

                return lhsProvider.priority > rhsProvider.priority
            },
            by: { provider in
                let priority = await provider.getPriority()
                let expectedAmount = await provider.getState().quote?.expectAmount ?? 0
                return (priority, expectedAmount)
            }
        )
    }

    func showableProviders(selectedProviderId: String?) async -> [ExpressAvailableProvider] {
        await asyncFilter { provider in
            guard provider.isAvailable else {
                return false
            }

            // If the provider `isSelected` we are forced to show it anyway
            let isSelected = selectedProviderId == provider.provider.id
            let isAvailableToShow = await !provider.getState().isError

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
