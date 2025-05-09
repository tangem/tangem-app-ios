//
//  WalletConnectQRScanViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

// [REDACTED_TODO_COMMENT]
struct WalletConnectQRScanViewState {
    let navigationBar = NavigationBar()
    let hint = "Open Web3 app and chose WalletConnect option"
    let pasteFromClipboardButton: PasteFromClipboardButton?
    var hasCameraAccess = false
    var confirmationDialog: ConfirmationDialog?
}

extension WalletConnectQRScanViewState {
    struct NavigationBar {
        let title = Localization.wcNewConnection
        let closeButtonTitle = Localization.commonClose
    }

    struct PasteFromClipboardButton {
        let clipboardURI: WalletConnectRequestURI
        let title = Localization.walletConnectPasteFromClipboard
        let asset = Assets.Glyphs.copy
    }

    struct ConfirmationDialog {
        let title: String
        let subtitle: String
        let buttons: [DialogButton]

        static func cameraAccessDenied(
            openSystemSettingsAction: @escaping () -> Void,
            pasteFromClipboardAction: (() -> Void)?
        ) -> ConfirmationDialog {
            var buttons = [
                DialogButton(title: Localization.commonCameraAlertButtonSettings, role: nil, action: openSystemSettingsAction),
            ]

            if let pasteFromClipboardAction {
                buttons.append(
                    DialogButton(
                        title: Localization.walletConnectPasteFromClipboard,
                        role: nil,
                        action: pasteFromClipboardAction
                    )
                )
            }

            return ConfirmationDialog(
                title: Localization.commonCameraDeniedAlertTitle,
                subtitle: Localization.commonCameraDeniedAlertMessage,
                buttons: buttons
            )
        }
    }

    struct DialogButton: Hashable {
        let title: String
        let role: DialogButtonRole?
        let action: () -> Void

        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(role)
        }

        static func == (lhs: WalletConnectQRScanViewState.DialogButton, rhs: WalletConnectQRScanViewState.DialogButton) -> Bool {
            lhs.title == rhs.title && lhs.role == rhs.role
        }
    }

    enum DialogButtonRole: Hashable {
        case cancel
    }
}
