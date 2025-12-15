//
//  RecentOnrampTransactionParametersFinder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol RecentOnrampTransactionParametersFinder: AnyObject {
    var recentOnrampTransaction: RecentOnrampTransactionParameters? { get }
}

struct RecentOnrampTransactionParameters {
    let providerId: String
    let paymentMethodId: String
}
