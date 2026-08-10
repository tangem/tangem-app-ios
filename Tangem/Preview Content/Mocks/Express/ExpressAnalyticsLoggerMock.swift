//
//  ExpressAnalyticsLoggerMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk

struct ExpressAnalyticsLoggerMock: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: ExpressAvailableProvider) {}

    func logGasEstimationOverrideError(_ error: any Error) {}

    func logAppError(_ error: any Error, provider: ExpressProvider) {}

    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) {}
}
