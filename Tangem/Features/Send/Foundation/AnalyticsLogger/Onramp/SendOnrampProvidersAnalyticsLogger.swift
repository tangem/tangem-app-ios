//
//  SendOnrampProvidersAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol SendOnrampProvidersAnalyticsLogger {
    func logOnrampProvidersScreenOpened()
    func logOnrampProviderChosen(provider: ExpressProvider)
}
