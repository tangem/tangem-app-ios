//
//  MobileUpgradeBannerStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol MobileUpgradeBannerStorageManager: Initializable {
    func getBannerCloseDate(userWalletId: UserWalletId) -> Date?
    func getWalletCreateDate(userWalletId: UserWalletId) -> Date?
    func getWalletTopUpDate(userWalletId: UserWalletId) -> Date?

    func store(userWalletId: UserWalletId, bannerCloseDate: Date)
    func store(userWalletId: UserWalletId, walletTopUpDate: Date)
}
