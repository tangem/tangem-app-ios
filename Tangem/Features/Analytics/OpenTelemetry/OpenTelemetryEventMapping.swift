//
//  OpenTelemetryEventMapping.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct OpenTelemetryEventMapping {
    /// snake_case, no spaces — OTLP instrument names cannot contain the spaces our event names have.
    let metricName: String
    /// Event property keys that may be forwarded, mapped to their attribute name.
    let allowedProperties: [String: String]

    init(metricName: String, allowedProperties: [String: String] = [:]) {
        self.metricName = metricName
        self.allowedProperties = allowedProperties
    }
}

extension OpenTelemetryEventMapping {
    /// The metrics to mirror, keyed by `Analytics.Event.rawValue`. Empty until the metric names and
    /// the per-metric attribute allowlist are agreed with product and infra.
    static let all: [String: OpenTelemetryEventMapping] = [:]
}
