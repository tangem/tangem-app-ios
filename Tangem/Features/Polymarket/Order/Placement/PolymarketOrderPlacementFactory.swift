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

    func makeService(for userWalletModel: any UserWalletModel) -> PolymarketOrderPlacementService {
        let sessionKeyFactory = PolymarketSessionKeyFactory()
        let sessionKeySigner = sessionKeyFactory.makeOrderDigestSigner(for: userWalletModel)

        return CommonPolymarketOrderPlacementService(
            userWalletId: userWalletModel.userWalletId,
            ownerAddressProvider: CommonPolymarketOwnerAddressProvider(keysRepository: userWalletModel.keysRepository),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            placer: PolymarketOrderPlacer(
                clobService: services.makeCLOBService(walletId: userWalletModel.userWalletId.stringValue),
                digestSigner: CommonPolymarketOrderDigestSigner(
                    keysRepository: userWalletModel.keysRepository,
                    signer: userWalletModel.signer
                )
            ),
            sessionKeyPlacement: CommonPolymarketOrderPlacementService.SessionKeyPlacement(
                placer: PolymarketOrderPlacer(clobService: services.makeCLOBService(), digestSigner: sessionKeySigner),
                signer: sessionKeySigner,
                router: sessionKeyFactory.makeSigningRouter(for: userWalletModel)
            )
        )
    }
}
