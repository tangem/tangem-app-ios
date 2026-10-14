//
//  MobileMainHeaderProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct MobileMainHeaderProviderFactory: MainHeaderProviderFactory {
    func makeHeaderBalanceProvider(for model: UserWalletModel) -> MainHeaderBalanceProvider {
        CommonMainHeaderBalanceProvider(
            totalBalanceProvider: model,
            userWalletStateInfoProvider: model,
            mainBalanceFormatter: MainHeaderBalanceFormatter()
        )
    }
}
