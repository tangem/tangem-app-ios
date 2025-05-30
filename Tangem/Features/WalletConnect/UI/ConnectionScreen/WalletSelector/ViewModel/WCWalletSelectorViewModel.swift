//
//  WCWalletSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class WCWalletSelectorViewModel: ObservableObject {
    let userWalletModels: [UserWalletModel]

    private let selectedWalletId: String
    private let selectWallet: (UserWalletModel) -> Void
    private let backAction: () -> Void

    init(input: WCWalletSelectorInput) {
        selectedWalletId = input.selectedWalletId
        userWalletModels = input.userWalletModels.filter { $0.config.isFeatureVisible(.walletConnect) }
        selectWallet = input.selectWallet
        backAction = input.backAction
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .selectWallet(let userWalletModel):
            selectWallet(userWalletModel)
        case .returnToConnectionDetails:
            backAction()
        }
    }

    func checkNotLastListItem(_ userWalletModel: UserWalletModel) -> Bool {
        userWalletModel.userWalletId != userWalletModels.last?.userWalletId
    }

    func checkSelectedWallet(_ userWalletModelId: String) -> Bool {
        selectedWalletId == userWalletModelId
    }
}

extension WCWalletSelectorViewModel {
    enum ViewAction {
        case selectWallet(UserWalletModel)
        case returnToConnectionDetails
    }
}
