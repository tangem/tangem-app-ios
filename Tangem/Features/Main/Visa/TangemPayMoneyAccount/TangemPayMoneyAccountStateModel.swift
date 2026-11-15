//
//  TangemPayMoneyAccountStateModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayMoneyAccountStateModel {
    var balance: FormattedTokenBalanceType
    var transactionHistory: TransactionsListView.State
    var isTrxHistoryReloading = false
    var fetchMore: FetchMore?
    var notificationBannerItems: [NotificationBannerItem] = []
    var isStale = false
}
