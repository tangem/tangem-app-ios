//
//  OpenTelemetryMetricsService.swift
//  TangemOpenTelemetry
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `name` is the metric name stored in monitoring: lowercase snake_case, the same on iOS and Android, without a platform suffix, e.g. `total_balance_loaded`.
public protocol OpenTelemetryMetricsService: AnyObject {
    var isStarted: Bool { get }

    func start(configuration: OTLPConfiguration)

    @discardableResult
    func increment(_ name: String, by value: Int, attributes: [String: String]) -> Bool

    @discardableResult
    func record(_ name: String, milliseconds: Double, buckets: OpenTelemetryHistogramBuckets, attributes: [String: String]) -> Bool
}
