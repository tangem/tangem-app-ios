//
//  ForYouCoordinator+Yield.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
extension ForYouCoordinator {
    func openEarnYield(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        runTask(in: self) { coordinator in
            let destination = await YieldModuleDestinationResolver().resolve(
                walletModel: walletModel,
                userWalletModel: userWalletModel
            )

            switch destination {
            case .promo(let apy, let flowFactory):
                coordinator.openYieldPromo(apy: apy, factory: flowFactory)
            case .active(let flowFactory):
                coordinator.openYieldActive(factory: flowFactory)
            case nil:
                coordinator.routeOnTokenResolvedAction(
                    .alreadyAdded(walletModel: walletModel, userWalletModel: userWalletModel),
                    .forYou
                )
            }
        }
    }
}

private extension ForYouCoordinator {
    func openYieldPromo(apy: Decimal, factory: YieldModuleFlowFactory) {
        yieldPromoCoordinator = factory.makeYieldPromoCoordinator(
            apy: apy,
            isApyBoostPromo: false,
            dismissAction: { [weak self] _ in
                self?.dismissYield()
            }
        )
    }

    func openYieldActive(factory: YieldModuleFlowFactory) {
        yieldActiveCoordinator = factory.makeYieldActiveCoordinator(
            dismissAction: { [weak self] _ in
                self?.dismissYield()
            }
        )
    }

    func dismissYield() {
        yieldPromoCoordinator = nil
        yieldActiveCoordinator = nil
    }
}
