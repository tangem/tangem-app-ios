//
//  PerformanceTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import FirebasePerformance
import TangemFoundation

enum PerformanceTracker {
    static func startTracking(metric: PerformanceTracker.Metric) -> PerformanceMetricToken? {
        if AppEnvironment.current.isDebug {
            return nil
        }

        let traceName: String

        switch metric {
        case .totalBalanceLoaded:
            traceName = "Total_balance_loaded"
        }

        let trace = Performance.startTrace(name: traceName)
        prepareTraceForStartTracking(trace, using: metric)

        return PerformanceMetricToken(trace: trace)
    }

    static func endTracking(token: PerformanceMetricToken?, with result: PerformanceTracker.Result = .unspecified) {
        if AppEnvironment.current.isDebug {
            return
        }

        prepareTraceForEndTracking(token?.trace, with: result)
        token?.stop()
    }

    private static func prepareTraceForStartTracking(_ trace: Trace?, using metric: PerformanceTracker.Metric) {
        switch metric {
        case .totalBalanceLoaded(let tokensCount):
            trace?.setValue(String(tokensCount), forAttribute: Attributes.tokensCount.rawValue)
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
final class PerformanceMetricToken {
    fileprivate let trace: Trace?
    private var isStopped = false

    fileprivate init(trace: Trace?) {
        self.trace = trace
    }

    deinit {
        if !isStopped, let trace {
            AppLogger.error(error: "The trace '\(trace.name)' is still running; it must be stopped by calling 'PerformanceTracker.endTracking(token:)'")
        }
    }

    fileprivate func stop() {
        trace?.stop()
        isStopped = true
    }
}

// MARK: - Constants

private extension PerformanceTracker {
    enum Attributes: String {
        case hasError = "has_error"
        case tokensCount = "tokens_count"
    }

    enum Values {
        static var yes: String { Analytics.ParameterValue.yes.rawValue }
        static var no: String { Analytics.ParameterValue.no.rawValue }
    }
}
