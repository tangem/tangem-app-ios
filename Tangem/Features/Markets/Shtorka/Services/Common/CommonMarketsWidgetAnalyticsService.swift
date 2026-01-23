//
//  CommonMarketsWidgetAnalyticsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonMarketsWidgetAnalyticsService: MarketsWidgetAnalyticsProvider {
    func logMarketsLoadError(_ error: Error) {
        let analyticsParams = error.marketsAnalyticsParams
        Analytics.log(
            event: .marketsMarketsLoadError,
            params: [
                .errorCode: analyticsParams[.errorCode] ?? "",
                .errorMessage: analyticsParams[.errorMessage] ?? "",
            ]
        )
    }

    func logNewsLoadError(_ error: Error) {
        let analyticsParams = error.marketsAnalyticsParams
        Analytics.log(
            event: .marketsNewsLoadError,
            params: [
                .errorCode: analyticsParams[.errorCode] ?? "",
                .errorMessage: analyticsParams[.errorMessage] ?? "",
            ]
        )
    }
}
