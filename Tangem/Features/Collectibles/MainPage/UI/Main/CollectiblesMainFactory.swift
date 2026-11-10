//
//  CollectiblesMainFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import TangemAssets
import TangemUI
import TangemUIUtils

struct CollectiblesMainFactory {
    let accountModel: (any CollectiblesAccountModel)?
    let catalogueProvider: any CollectiblesLoresProvider & CollectiblesPacksProvider
    let signingActionButtonType: SigningActionButtonViewType

    @MainActor
    func makeViewModel(
        routable: (any CollectiblesMainRoutable)?,
        pendingPurchases: CollectiblesPendingPurchaseBannersViewModel?
    ) -> CollectiblesMainViewModel {
        let openMachine = makeOpenMachine(routable: routable, pendingPurchases: pendingPurchases)

        return CollectiblesMainViewModel(
            accountViewModel: CollectiblesAccountViewModel(accountModel: accountModel, routable: routable),
            loreTabsViewModel: CollectiblesLoreTabsViewModel(provider: catalogueProvider),
            packsViewModel: makePacksViewModel(onSelect: openMachine),
            searchResultsViewModel: makePacksViewModel { pack in
                UIApplication.shared.endEditing()
                openMachine(pack)
            }
        )
    }

    @MainActor
    func makeBanners(
        routable: (any CollectiblesMainRoutable)?,
        pendingPurchaseProvider: any CollectiblesPendingPurchaseProvider
    ) -> CollectiblesAccountView.Banners {
        CollectiblesAccountView.Banners(
            relinkBannerViewModel: makeRelinkBannerViewModel(routable: routable),
            pendingPurchaseBannersViewModel: makePendingPurchaseBannersViewModel(
                provider: pendingPurchaseProvider,
                routable: routable
            )
        )
    }
}

// MARK: - Private logic

@MainActor
private extension CollectiblesMainFactory {
    func makeRelinkBannerViewModel(routable: (any CollectiblesMainRoutable)?) -> CollectiblesRelinkBannerViewModel? {
        let openReconnection = makeOpenReconnection(routable: routable)

        return accountModel.map {
            CollectiblesRelinkBannerViewModel(
                relinker: $0,
                openReconnection: openReconnection,
                closeCollectibles: { [weak routable] in routable?.closeCollectibles() }
            )
        }
    }

    func makePendingPurchaseBannersViewModel(
        provider: any CollectiblesPendingPurchaseProvider,
        routable: (any CollectiblesMainRoutable)?
    ) -> CollectiblesPendingPurchaseBannersViewModel? {
        accountModel.map { accountModel in
            CollectiblesPendingPurchaseBannersViewModel(
                provider: provider,
                machineProvider: CollectiblesAPIService(),
                isDelivered: { [purchaseInteractor = accountModel.purchaseInteractor] txID in
                    purchaseInteractor.isDelivered(txID: txID)
                },
                openUnfinishedPurchase: { [weak routable] purchase, machine in
                    routable?.openUnfinishedPurchase(purchase, machine: machine)
                }
            )
        }
    }

    func makeOpenMachine(
        routable: (any CollectiblesMainRoutable)?,
        pendingPurchases: CollectiblesPendingPurchaseBannersViewModel?
    ) -> (CollectiblesPack) -> Void {
        { [weak routable, weak pendingPurchases] pack in
            guard pendingPurchases?.presentSheetIfPurchaseUnfinished() != true else {
                return
            }

            routable?.openMachine(for: pack)
        }
    }

    func makeOpenReconnection(routable: (any CollectiblesMainRoutable)?) -> (@MainActor () -> Void)? {
        switch signingActionButtonType {
        case .requiredNFCInteraction: nil
        case .holdToConfirm: { [weak routable] in routable?.openReconnection() }
        }
    }

    func makePacksViewModel(onSelect: @escaping (CollectiblesPack) -> Void) -> CollectiblesPacksViewModel {
        CollectiblesPacksViewModel(model: CollectiblesPacksModel(provider: catalogueProvider), packSelectionHandler: onSelect)
    }
}
