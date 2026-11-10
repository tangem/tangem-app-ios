//
//  PolymarketOrderPlacementFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketOrderPlacementFactory {
    private let services = PolymarketOnboardingServicesFactory.makeDefault()

    func makeService(
        for userWalletModel: any UserWalletModel,
        signingRouter: PolymarketOrderSigningRouting
    ) -> PolymarketOrderPlacementService {
        CommonPolymarketOrderPlacementService(
            userWalletId: userWalletModel.userWalletId,
            ownerAddressProvider: CommonPolymarketOwnerAddressProvider(keysRepository: userWalletModel.keysRepository),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            placer: PolymarketOrderPlacer(
                clobService: services.makeOwnerCLOBService(userWalletId: userWalletModel.userWalletId),
                signing: .depositWallet(
                    CommonPolymarketOrderDigestSigner(
                        keysRepository: userWalletModel.keysRepository,
                        signer: userWalletModel.signer
                    )
                )
            ),
            sessionKeyPlacement: CommonPolymarketOrderPlacementService.SessionKeyPlacement(
                placer: PolymarketOrderPlacer(
                    clobService: services.makeSessionKeyCLOBService(),
                    signing: .sessionKey(PolymarketSessionKeyFactory().makeOrderDigestSigner(for: userWalletModel))
                ),
                router: signingRouter
            )
        )
    }
}
