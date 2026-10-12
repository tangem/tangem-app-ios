//
//  PolymarketPositionsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketPositionsFactory {
    func makeService(
        for userWalletModel: any UserWalletModel,
        apiProvider: PolymarketAPIProvider
    ) -> PolymarketPositionsService {
        CommonPolymarketPositionsService(
            ownerAddressProvider: PolymarketOnboardingFactory().makeOwnerAddressProvider(for: userWalletModel),
            apiProvider: apiProvider
        )
    }
}
