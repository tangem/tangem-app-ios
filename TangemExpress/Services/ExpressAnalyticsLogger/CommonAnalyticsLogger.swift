//
//  CommonExpressAnalyticsLogger.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonExpressAnalyticsLogger: ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: ExpressAvailableProvider) {
        print("Best provider selected: \(provider.provider.name)")
    }
}
