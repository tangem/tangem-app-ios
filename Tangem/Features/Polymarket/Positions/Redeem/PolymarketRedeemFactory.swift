//
//  PolymarketRedeemFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketRedeemFactory {
    private let services = PolymarketOnboardingServicesFactory.makeDefault()

    func makeService(
        for userWalletModel: any UserWalletModel,
        sessionHealth: PolymarketSessionHealthChecking
    ) -> PolymarketRedeeming {
        let walletId = userWalletModel.userWalletId.stringValue

        return PolymarketRedeemTransactionService(
            redeemService: services.makeRedeemService(walletId: walletId),
            relayerService: services.makeRelayerService(),
            depositWalletResolver: PolymarketDepositWalletResolver(
                walletService: services.makeWalletService(walletId: walletId),
                ownerAddressProvider: PolymarketOnboardingFactory().makeOwnerAddressProvider(for: userWalletModel),
                sessionHealth: sessionHealth
            ),
            signer: PolymarketBatchSigner(
                keysRepository: userWalletModel.keysRepository,
                signer: userWalletModel.signer
            ),
            serverClock: InjectedValues[\.polymarketServerClock]
        )
    }
}
