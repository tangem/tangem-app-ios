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
    func makeViewModel(routable: (any CollectiblesMainRoutable)?) -> CollectiblesMainViewModel {
        CollectiblesMainViewModel(
            accountViewModel: CollectiblesAccountViewModel(accountModel: accountModel, routable: routable),
            loreTabsViewModel: CollectiblesLoreTabsViewModel(provider: catalogueProvider),
            packsViewModel: makePacksViewModel { [weak routable] pack in
                routable?.openMachine(for: pack)
            },
            searchResultsViewModel: makePacksViewModel { [weak routable] pack in
                UIApplication.shared.endEditing()
                routable?.openMachine(for: pack)
            }
        )
    }

    @MainActor
    func makeBanners(routable: (any CollectiblesMainRoutable)?) -> CollectiblesAccountView.Banners {
        CollectiblesAccountView.Banners(relinkBannerViewModel: makeRelinkBannerViewModel(routable: routable))
    }
}

// MARK: - Private logic

@MainActor
private extension CollectiblesMainFactory {
    func makeRelinkBannerViewModel(routable: (any CollectiblesMainRoutable)?) -> CollectiblesRelinkBannerViewModel? {
        let openReconnection = makeOpenReconnection(routable: routable)

        return accountModel.map { CollectiblesRelinkBannerViewModel(relinker: $0, openReconnection: openReconnection) }
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
