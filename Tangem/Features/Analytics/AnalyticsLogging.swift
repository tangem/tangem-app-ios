//
//  AnalyticsLogging.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Thin abstraction over the static `Analytics.log` API so call sites can be unit-tested
/// with a spy. Production code uses `CommonAnalyticsLogger`, which forwards to `Analytics`.
protocol AnalyticsLogging {
    func log(
        event: Analytics.Event,
        params: [Analytics.ParameterKey: String],
        analyticsSystems: [Analytics.AnalyticsSystem]
    )
}

extension AnalyticsLogging {
    func log(event: Analytics.Event, params: [Analytics.ParameterKey: String] = [:]) {
        log(event: event, params: params, analyticsSystems: .defaultSystems)
    }

    func log(_ event: Analytics.Event) {
        log(event: event, params: [:], analyticsSystems: .defaultSystems)
    }

    func log(_ event: Analytics.Event, params: [Analytics.ParameterKey: Analytics.ParameterValue]) {
        log(event: event, params: params.mapValues { $0.rawValue }, analyticsSystems: .defaultSystems)
    }

    func log(
        _ event: Analytics.Event,
        params: [Analytics.ParameterKey: Analytics.ParameterValue] = [:],
        analyticsSystems: [Analytics.AnalyticsSystem] = .defaultSystems
    ) {
        log(event: event, params: params.mapValues { $0.rawValue }, analyticsSystems: analyticsSystems)
    }
}

struct CommonAnalyticsLogger: AnalyticsLogging {
    func log(
        event: Analytics.Event,
        params: [Analytics.ParameterKey: String],
        analyticsSystems: [Analytics.AnalyticsSystem]
    ) {
        Analytics.log(event: event, params: params, analyticsSystems: analyticsSystems)
    }
}
