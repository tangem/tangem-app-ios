//
//  CommonAnalyticsContextDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonAnalyticsContextDataProvider {
    private let walletInfo: WalletInfo
    private weak var userWalletModel: (any UserWalletModel)?

    init(walletInfo: WalletInfo) {
        self.walletInfo = walletInfo
    }

    func configure(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

// MARK: - AnalyticsContextDataProvider

extension CommonAnalyticsContextDataProvider: AnalyticsContextDataProvider {
    var analyticsContextData: AnalyticsContextData {
        userWalletModel?.analyticsContextData ?? walletInfo.analyticsContextData
    }
}
