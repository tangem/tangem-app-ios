//
//  ExpressAnalyticsLogger.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressAnalyticsLogger {
    func bestProviderSelected(_ provider: ExpressAvailableProvider)
}
