//
//  MarketsWidgetAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Protocol for logging analytics events related to Markets widgets.
protocol MarketsWidgetAnalyticsProvider {
    /// Logs an error event for Markets/Pulse widget load failure.
    /// - Parameter error: The error that occurred during loading.
    func logMarketsLoadError(_ error: Error)

    /// Logs an error event for News widget load failure.
    /// - Parameter error: The error that occurred during loading.
    func logNewsLoadError(_ error: Error)
}
