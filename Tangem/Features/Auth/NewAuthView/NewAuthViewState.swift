//
//  NewAuthViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.ConfirmationDialogViewModel

enum NewAuthViewState {
    case locked
    case wallets(WalletsState)

    mutating func show(scanTroubleshootingDialog dialogViewModel: ConfirmationDialogViewModel, placement: ScanTroubleshootingDialog.Placement) {
        guard case .wallets(var walletsState) = self else {
            assertionFailure("Invalid state \(self) for showing dialog. Developer mistake.")
            return
        }

        walletsState.scanTroubleshootingDialog = ScanTroubleshootingDialog(viewModel: dialogViewModel, placement: placement)
        self = .wallets(walletsState)
    }

    mutating func hideScanTroubleshootingDialog() {
        guard case .wallets(var walletsState) = self else {
            assertionFailure("Invalid state \(self) for showing dialog. Developer mistake.")
            return
        }

        walletsState.scanTroubleshootingDialog = nil
        self = .wallets(walletsState)
    }
}

extension NewAuthViewState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.locked, .locked): true
        case (.wallets, .wallets): true
        default: false
        }
    }
}

extension NewAuthViewState {
    struct WalletsState {
        let title = Localization.welcomeUnlockTitle
        let description = Localization.authInfoSubtitle
        let addWalletButton: Button
        let biometricsUnlockButton: Button?
        let wallets: [WalletItem]
        var scanTroubleshootingDialog: ScanTroubleshootingDialog?
    }

    struct WalletItem: Identifiable {
        let id: UserWalletId
        let title: String
        let description: String
        let imageProvider: WalletImageProviding
        let isProtected: Bool
        let isUnlocking: (UserWalletId?) -> Bool
        let action: () -> Void
    }

    struct Button {
        let title: String
        let action: () -> Void

        static func addWallet(action: @escaping () -> Void) -> Button {
            Button(title: Localization.authInfoAddWalletTitle, action: action)
        }

        static func biometricsUnlock(biometryType: String, action: @escaping () -> Void) -> Button {
            Button(title: Localization.userWalletListUnlockAllWith(biometryType), action: action)
        }
    }

    struct ScanTroubleshootingDialog {
        enum Placement {
            case addWalletButton
            case wallet(UserWalletId)
        }

        let viewModel: ConfirmationDialogViewModel
        let placement: Placement
    }
}
