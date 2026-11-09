//
//  OpenTelemetryHistogramBuckets.swift
//  TangemOpenTelemetry
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum OpenTelemetryHistogramBuckets: Hashable, Sendable {
    case main
    case short

    var boundaries: [Double] {
        switch self {
        case .main: [250, 500, 1000, 2000, 5000, 10000, 30000]
        case .short: [250, 500, 1000, 3000, 10000]
        }
    }
}
