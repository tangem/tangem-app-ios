//
//  PolymarketAccountBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemPolymarket

struct PolymarketAccountBuilder {
    private let userWalletId: UserWalletId
    private let keysRepository: KeysRepository

    init(userWalletId: UserWalletId, keysRepository: KeysRepository) {
        self.userWalletId = userWalletId
        self.keysRepository = keysRepository
    }

    func hasAccount() -> Bool {
        AppSettings.shared.hasAccount(userWalletId: userWalletId)
    }

    func buildAccountModel() -> any PolymarketAccountModel {
        let services = PolymarketOnboardingServicesFactory.makeDefault()

        return CommonPolymarketAccountModel(
            userWalletId: userWalletId,
            walletService: services.makeWalletService(walletId: userWalletId.stringValue),
            clobService: services.makeCLOBService(),
            positionsValueService: services.makePositionsValueService(),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            ownerAddressProvider: CommonPolymarketOwnerAddressProvider(keysRepository: keysRepository),
            balanceService: CommonPolymarketBalanceService(
                tokenBalancesRepository: CommonTokenBalancesRepository(userWalletId: userWalletId)
            ),
            presenceStore: AppSettings.shared
        )
    }
}
