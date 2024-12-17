//
//  ExpressAnalyticsLoggerMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExpressAnalyticsLoggerMock: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: TangemExpress.ExpressAvailableProvider) {}

    func logAppError(_ error: any Error, provider: TangemExpress.ExpressProvider) {}

    func logExpressAPIError(_ error: TangemExpress.ExpressAPIError, provider: TangemExpress.ExpressProvider) {}
}
