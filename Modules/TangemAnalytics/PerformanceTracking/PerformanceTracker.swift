//
//  PerformanceTracker.swift
//  TangemAnalytics
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLogger
import TangemFirebaseDynamicShim

public enum PerformanceTracker {
    public static func startTracking(metric: PerformanceTracker.Metric) -> PerformanceMetricToken? {
        if AppEnvironment.current.isDebug {
            return nil
        }

        let traceName: String

        switch metric {
        case .totalBalanceLoaded:
            traceName = "Total_balance_loaded"
        case .swapQuotesLoaded:
            traceName = "Swap_quotes_loaded"
        }

        let trace = Performance.startTrace(name: traceName)
        prepareTraceForStartTracking(trace, using: metric)

        return PerformanceMetricToken(traceName: traceName) { result in
            prepareTraceForEndTracking(trace, with: result)
            trace?.stop()
        }
    }

    public static func endTracking(token: PerformanceMetricToken?, with result: PerformanceTracker.Result = .unspecified) {
        token?.end(with: result)
    }

    private static func prepareTraceForStartTracking(_ trace: Trace?, using metric: PerformanceTracker.Metric) {
        switch metric {
        case .totalBalanceLoaded(let tokensCount):
            trace?.setValue(String(tokensCount), forAttribute: Attributes.tokensCount.rawValue)
        case .swapQuotesLoaded(let providersCount):
            trace?.setValue(String(providersCount), forAttribute: Attributes.providersCount.rawValue)
        }
    }

    private static func prepareTraceForEndTracking(_ trace: Trace?, with result: PerformanceTracker.Result) {
        switch result {
        case .failure:
            trace?.setValue(Values.yes, forAttribute: Attributes.hasError.rawValue)
        case .success:
            trace?.setValue(Values.no, forAttribute: Attributes.hasError.rawValue)
        case .unspecified:
            break
        }
    }
}

// MARK: - Auxiliary types

/// An opaque token to use with `PerformanceTracker.endTracking(token:)` method.
public final class PerformanceMetricToken {
    private let traceName: String
    private let isEnded = OSAllocatedUnfairLock(initialState: false)
    private let endOperation: (PerformanceTracker.Result) -> Void

    init(
        traceName: String,
        endOperation: @escaping (PerformanceTracker.Result) -> Void
    ) {
        self.traceName = traceName
        self.endOperation = endOperation
    }

    deinit {
        if AppEnvironment.current.isDebug {
            return
        }

        let ended = isEnded { $0 }
        if !ended {
            PerformanceTrackingLogger.error(
                error: "The trace '\(traceName)' is still running; it must be stopped by calling 'PerformanceTracker.endTracking(token:)'."
            )
        }
    }

    func end(with result: PerformanceTracker.Result) {
        let alreadyEnded = isEnded { state in
            let previousState = state
            state = true
            return previousState
        }

        guard !alreadyEnded else {
            return
        }

        endOperation(result)
    }
}

// MARK: - Constants

private extension PerformanceTracker {
    enum Attributes: String {
        case hasError = "has_error"
        case tokensCount = "tokens_count"
        case providersCount = "providers_count"
    }

    enum Values {
        static let yes = "Yes" // [REDACTED_TODO_COMMENT]
        static let no = "No" // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Module-local logger

private let PerformanceTrackingLogger = Logger(category: OSLogCategory(name: "PerformanceTracking"))
