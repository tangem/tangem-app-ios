//
//  AddWalletTypeSelectorSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

@MainActor
final class AddWalletTypeSelectorSheetViewModel: FloatingSheetContentViewModel {
    private weak var output: AddWalletTypeSelectorSheetOutput?
    private weak var coordinator: AddWalletTypeSelectorSheetRoutable?

    init(output: AddWalletTypeSelectorSheetOutput, coordinator: AddWalletTypeSelectorSheetRoutable) {
        self.output = output
        self.coordinator = coordinator
    }

    func onHardwareWalletTap() {
        Analytics.log(.settingsButtonAddHardwareWallet, params: analyticsParams)

        coordinator?.closeAddWalletTypeSelectorSheet()
        output?.addWalletTypeSelectorDidRequestHardwareWallet()
    }

    /// The sheet stays open, the coming soon alert is shown above it
    func onMobileWalletTap() {
        Analytics.log(.settingsButtonAddMobileWallet, params: analyticsParams)
        Analytics.log(.settingsNoticeMoreMobileWallets, params: analyticsParams)

        output?.addWalletTypeSelectorDidRequestMobileWallet()
    }

    func onCloseTap() {
        coordinator?.closeAddWalletTypeSelectorSheet()
    }
}

// MARK: - Analytics

private extension AddWalletTypeSelectorSheetViewModel {
    var analyticsParams: [Analytics.ParameterKey: Analytics.ParameterValue] {
        let walletsType: Analytics.ParameterValue = switch UserWalletRepositoryModeHelper.mode {
        case .mobile: .walletsTypeMobile
        case .hardware: .walletsTypeCold
        case .mixed: .walletsTypeMultiple
        case .empty: .unknown
        }

        return [.wallets: walletsType]
    }
}
