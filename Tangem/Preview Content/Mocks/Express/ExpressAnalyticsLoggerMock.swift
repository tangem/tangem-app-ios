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
    func bestProviderSelected(_ provider: TangemExpress.ExpressAvailableProvider) {}

    func logAppError(_ error: any Error, provider: TangemExpress.ExpressProvider) {}

    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) {}

    func logExpressError(_ error: ExpressAPIError) async {}

    func logExpressError(_ error: Error, provider: ExpressProvider?) {}

    func logSwapTransactionAnalyticsEvent(destination: String?) {}

    func logApproveTransactionAnalyticsEvent(policy: ApprovePolicy, destination: String?) {}

    func logApproveTransactionSentAnalyticsEvent(policy: ApprovePolicy, signerType: String, currentProviderHost: String) {}
}
