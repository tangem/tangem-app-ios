//
//  EarnWidgetRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol EarnWidgetRoutable: AnyObject {
    func openSeeAllEarnWidget()
    func openAddEarnToken(_ token: EarnTokenModel, userWalletModels: [UserWalletModel])
}
