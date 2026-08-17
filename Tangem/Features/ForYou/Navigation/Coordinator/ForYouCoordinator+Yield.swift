//
//  ForYouCoordinator+Yield.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
extension ForYouCoordinator {
    func openEarnYield(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        yieldDeeplinkRouter = YieldDeeplinkRouter(
            discardIncomingAction: { [weak self] in
                self?.routeOnTokenResolvedAction(
                    .alreadyAdded(walletModel: walletModel, userWalletModel: userWalletModel),
                    .forYou
                )
            },
            openYieldPromoAction: { [weak self] apy, factory in
                self?.openYieldPromo(apy: apy, factory: factory)
            },
            openYieldActiveAction: { [weak self] factory in
                self?.openYieldActive(factory: factory)
            },
            onFinish: { [weak self] in
                self?.yieldDeeplinkRouter = nil
            }
        )

        yieldDeeplinkRouter?.handle(walletModel: walletModel, userWalletModel: userWalletModel)
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
