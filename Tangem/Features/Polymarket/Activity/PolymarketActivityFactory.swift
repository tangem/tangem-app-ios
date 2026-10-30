//
//  PolymarketActivityFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketActivityFactory {
    func makeService(
        for userWalletModel: any UserWalletModel,
        apiProvider: PolymarketAPIProvider
    ) -> PolymarketActivityService {
        CommonPolymarketActivityService(
            ownerAddressProvider: PolymarketOnboardingFactory().makeOwnerAddressProvider(for: userWalletModel),
            apiProvider: apiProvider
        )
    }
}
