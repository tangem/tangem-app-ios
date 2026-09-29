//
//  TangemPayOtherNetworksSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemUI

@MainActor
final class TangemPayOtherNetworksSheetViewModel: FloatingSheetContentViewModel {
    private weak var coordinator: TangemPayOtherNetworksSheetRoutable?

    init(userWalletId: UserWalletId, coordinator: TangemPayOtherNetworksSheetRoutable) {
        self.coordinator = coordinator

        Analytics.log(.visaMultichainOtherWaySwapPopupShowed, contextParams: .userWallet(userWalletId))
    }

    func close() {
        coordinator?.closeOtherNetworksSheet()
    }
}
