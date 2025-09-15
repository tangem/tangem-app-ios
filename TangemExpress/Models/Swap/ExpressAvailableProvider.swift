//
//  ExpressAvailableProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

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

public extension ExpressAvailableProvider {
    enum Priority: Comparable {
        case lowest
        case low
        case medium(minimumAmount: Decimal)
        case high(rate: Decimal)
        case highest
    }
}
