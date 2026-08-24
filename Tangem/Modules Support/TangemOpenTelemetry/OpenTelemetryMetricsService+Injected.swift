//
//  OpenTelemetryMetricsService+Injected.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemOpenTelemetry

extension InjectedValues {
    var openTelemetryMetricsService: OpenTelemetryMetricsService {
        get { Self[OpenTelemetryMetricsServiceKey.self] }
        set { Self[OpenTelemetryMetricsServiceKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct OpenTelemetryMetricsServiceKey: InjectionKey {
    static var currentValue: OpenTelemetryMetricsService = CommonOpenTelemetryMetricsService()
}
