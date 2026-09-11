//
//  OpenTelemetryMetricsService.swift
//  TangemOpenTelemetry
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol OpenTelemetryMetricsService: AnyObject {
    var isStarted: Bool { get }

    func start(configuration: OTLPConfiguration)

    @discardableResult
    func increment(_ name: String, by value: Int, attributes: [String: String]) -> Bool
}
