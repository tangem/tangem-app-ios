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
        CommonPolymarketOrderPlacementService(
            userWalletId: userWalletModel.userWalletId,
            ownerAddressProvider: CommonPolymarketOwnerAddressProvider(keysRepository: userWalletModel.keysRepository),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            placer: PolymarketOrderPlacer(
                clobService: services.makeCLOBService(),
                digestSigner: CommonPolymarketOrderDigestSigner(
                    keysRepository: userWalletModel.keysRepository,
                    signer: userWalletModel.signer
                )
            )
        )
    }
}
