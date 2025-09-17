//
//  NetworkProviderAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol NetworkProviderAnalyticsLogger {
    var currentNetworkProviderHost: String { get }
}

struct CommonNetworkProviderAnalyticsLogger {
    let dataProvider: BlockchainDataProvider
}

// MARK: - CommonNetworkProviderAnalyticsLogger

extension CommonNetworkProviderAnalyticsLogger: NetworkProviderAnalyticsLogger {
    var currentNetworkProviderHost: String {
        dataProvider.currentHost
    }
}
