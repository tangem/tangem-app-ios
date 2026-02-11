//
//  TangemPayWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct TangemPayWalletSelectorViewModel {
    private var dataSource: TangemPayWalletSelectorDataSource

    let walletSelectorViewModel: WalletSelectorViewModel
    let onClose: () -> Void

    init(
        userWalletModels: [UserWalletModel],
        onSelect: @escaping (UserWalletModel) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.onClose = onClose
        dataSource = .init(
            userWalletModels: userWalletModels,
            onSelect: onSelect
        )
        walletSelectorViewModel = .init(dataSource: dataSource)
    }

    func onAppear() {
        Analytics.log(.visaOnboardingChooseWalletPopup)
    }
}

extension TangemPayWalletSelectorViewModel: FloatingSheetContentViewModel {
    var id: String {
        dataSource.userWalletModels
            .map { $0.userWalletId.stringValue }
            .joined()
    }
}
