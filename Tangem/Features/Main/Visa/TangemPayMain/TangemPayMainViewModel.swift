//
//  TangemPayMainViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayMainViewModel {
    let viewWalletMainContentViewModel: VisaWalletMainContentViewModel
    let mainHeaderViewModel: MainHeaderViewModel

    init(viewWalletMainContentViewModel: VisaWalletMainContentViewModel) {
        self.viewWalletMainContentViewModel = viewWalletMainContentViewModel

        // [REDACTED_TODO_COMMENT]
        mainHeaderViewModel = MainHeaderViewModel(
            isUserWalletLocked: false,
            supplementInfoProvider: viewWalletMainContentViewModel.visaDataProvider,
            subtitleProvider: VisaWalletMainHeaderSubtitleProvider(
                isUserWalletLocked: false,
                dataSource: viewWalletMainContentViewModel.visaDataProvider
            ),
            balanceProvider: viewWalletMainContentViewModel.visaDataProvider
        )
    }
}

/// Stub confirmance for this vm to be able to be used in CardsInfoPagerView
extension TangemPayMainViewModel: Identifiable {
    var id: Int { 0 }
}
