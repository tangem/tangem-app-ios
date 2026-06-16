//
//  ExpressQuotesLoadingPerformanceTracker.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemAnalytics

final class ExpressQuotesLoadingPerformanceTracker {
    private let providersCount: Int
    private let protectedState = OSAllocatedUnfairLock(initialState: State())
    private let endTracking: (PerformanceTracker.Result) -> Void

    init(
        providersCount: Int,
        endTracking: @escaping (PerformanceTracker.Result) -> Void
    ) {
        self.providersCount = providersCount
        self.endTracking = endTracking
    }

    deinit {
        endTracking(.unspecified)
    }

    func fulfill(hasError: Bool) {
        let result: PerformanceTracker.Result? = protectedState { state in
            let nextCount = state.fulfilledProvidersCount + 1
            let aggregatedHasError = state.hasError || hasError

            state.fulfilledProvidersCount = nextCount
            state.hasError = aggregatedHasError

            guard nextCount == providersCount else {
                return nil
            }

            return aggregatedHasError ? .failure : .success
        }

        if let result {
            endTracking(result)
        }
    }
}

// MARK: - Convenience extensions

extension ExpressQuotesLoadingPerformanceTracker {
    static func started(providersCount: Int) -> ExpressQuotesLoadingPerformanceTracker {
        let token = PerformanceTracker.startTracking(
            metric: .swapQuotesLoaded(providersCount: providersCount)
        )

        return ExpressQuotesLoadingPerformanceTracker(providersCount: providersCount) { result in
            PerformanceTracker.endTracking(token: token, with: result)
        }
    }
}

// MARK: - Auxiliary types

private extension ExpressQuotesLoadingPerformanceTracker {
    struct State {
        var fulfilledProvidersCount = 0
        var hasError = false
    }
}
