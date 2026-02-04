//
//  EarnDetailRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol EarnDetailRoutable: AnyObject {
    func dismiss()
    func openAddEarnToken(for token: EarnTokenModel, userWalletModels: [UserWalletModel])
    func openNetworksFilter()
    func openTypesFilter()
}
