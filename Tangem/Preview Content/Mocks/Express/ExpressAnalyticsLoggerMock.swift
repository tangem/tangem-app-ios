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

    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) {}

    func logExpressError(_ error: ExpressAPIError) async {}

    func logExpressError(_ error: ExpressAPIError, provider: ExpressProvider?) {}

    func logSwapTransactionAnalyticsEvent(destination: String?) {}

    func logApproveTransactionAnalyticsEvent(policy: TangemExpress.ExpressApprovePolicy, destination: String?) {}

    func logApproveTransactionSentAnalyticsEvent(policy: TangemExpress.ExpressApprovePolicy, signerType: String) {}
}
